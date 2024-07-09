import os
import subprocess
import tempfile
from typing import Tuple, Dict
import json

def estimate_resource_cost(tf_plan_json) -> Tuple[float, Dict]:
    with tempfile.TemporaryDirectory() as temp_dir:
        plan_file = os.path.join(temp_dir, "plan.json")
        with open(plan_file, 'w') as f:
            f.write(tf_plan_json)

        try:
            infracost_output = subprocess.run(
                ["infracost", "breakdown", "--path", plan_file, "--format", "json"],
                check=True,
                capture_output=True,
                cwd=temp_dir
            )
            cost_data = json.loads(infracost_output.stdout)
            print(f"Cost data:\n\n\n\n{cost_data}")
            estimated_cost = float(cost_data['projects'][0]['breakdown']['totalMonthlyCost'])
            return estimated_cost, cost_data
        except subprocess.CalledProcessError as e:
            print(f"Error running Infracost: {e.stderr.decode('utf-8')}")
            raise

def format_cost_data_for_slack(cost_data):
    total_cost = float(cost_data['projects'][0]['breakdown']['totalMonthlyCost'])
    resources = cost_data['projects'][0]['breakdown']['resources']

    def format_cost(cost):
        return f"${float(cost):,.2f}"

    def format_cost_change(cost):
        if float(cost) > 0:
            return f":arrow_up: {format_cost(cost)} :money_with_wings:"
        elif float(cost) < 0:
            return f":arrow_down: {format_cost(cost)} :chart_with_downwards_trend:"
        else:
            return format_cost(cost)

    blocks = [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Estimated Monthly Cost:* {format_cost(total_cost)} :moneybag:"
            }
        },
        {"type": "divider"}
    ]

    for resource in resources:
        resource_name = resource['name']
        resource_type = resource['resourceType']
        monthly_cost = resource['monthlyCost']
        hourly_cost = resource['hourlyCost']
        cost_components = resource['costComponents']
        
        components_text = "\n".join([
            f"  - *{component['name']}*: {format_cost_change(component['monthlyCost'])} per {component['unit']}"
            for component in cost_components
        ])

        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*{resource_name} ({resource_type})*\nHourly: {format_cost(hourly_cost)}\nMonthly: {format_cost_change(monthly_cost)}\n*Cost Components:*\n{components_text}"
                }
            }
        )
        blocks.append({"type": "divider"})
    return {"blocks": blocks}

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Estimate the cost of a resource using Terraform and Infracost.')
    parser.add_argument('tf_plan_json', type=str, help='The Terraform plan JSON as a string')

    args = parser.parse_args()
    try:
        estimated_cost, cost_data = estimate_resource_cost(args.tf_plan_json)
        print(f"Calculated estimated monthly cost: ${estimated_cost:,.2f}")
        slack_message = format_cost_data_for_slack(cost_data)
    except Exception as e:
        print(f"❌ An error occurred: {e}")
