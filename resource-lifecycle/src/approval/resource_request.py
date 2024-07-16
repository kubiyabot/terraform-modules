import os
import argparse
import sqlite3
import uuid
import json
import requests
from datetime import datetime, timedelta
from pytimeparse.timeparse import timeparse
from models.models import ApprovalRequest
from slack.slack import SlackMessage
from llm.parse_request import parse_user_request, generate_terraform_code, fix_terraform_code
from iac.estimate_cost import estimate_resource_cost, format_cost_data_for_slack
from iac.compare_cost import compare_cost_with_avg, get_average_monthly_cost
from iac.terraform import apply_terraform, create_terraform_plan
from approval.scheduler import schedule_deletion_task

# Maximum number of retries for Terraform plan creation
MAX_TERRAFORM_RETRIES = int(os.getenv('MAX_TERRAFORM_RETRIES', 10))
APPROVAL_WORKFLOW = os.getenv('APPROVAL_WORKFLOW', '').lower() == 'true'
STORE_STATE = APPROVAL_WORKFLOW or os.getenv('STORE_STATE', 'true').lower() == 'true'
TTL_ENABLED = os.getenv('TTL_ENABLED', 'true').lower() == 'true'
USER_EMAIL = os.getenv('KUBIYA_USER_EMAIL')
SLACK_CHANNEL_ID = os.getenv('SLACK_CHANNEL_ID')
SLACK_THREAD_TS = os.getenv('SLACK_THREAD_TS')
KUBIYA_USER_ORG = os.getenv('KUBIYA_USER_ORG')
KUBIYA_API_KEY = os.getenv('KUBIYA_API_KEY')
APPROVAL_SLACK_CHANNEL = os.getenv('APPROVAL_SLACK_CHANNEL')
MAX_TTL = os.getenv('MAX_TTL', '30d')

def request_resource_creation_approval(request_id, purpose, resource_details, estimated_cost, tf_plan, cost_data, ttl, slack_thread_ts):
    requested_at = datetime.utcnow()

    ttl_seconds = timeparse(ttl)
    max_ttl_seconds = timeparse(MAX_TTL)

    if ttl_seconds is None or ttl_seconds > max_ttl_seconds:
        error_message = "TTL exceeds the maximum allowed TTL."
        print(f"❌ {error_message}")
        exit(1)

    expiry_time = requested_at + timedelta(seconds=int(ttl_seconds))

    if STORE_STATE:
        approval_request = ApprovalRequest(
            request_id=request_id,
            user_email=USER_EMAIL,
            purpose=purpose,
            cost=estimated_cost,
            requested_at=requested_at,
            ttl=ttl,
            expiry_time=expiry_time,
            slack_channel_id=SLACK_CHANNEL_ID,
            slack_thread_ts=slack_thread_ts
        )

        conn = sqlite3.connect('/sqlite_data/approval_requests.db')
        c = conn.cursor()

        c.execute('''CREATE TABLE IF NOT EXISTS approvals
                     (request_id text, user_email text, purpose text, cost real, requested_at text, ttl text, expiry_time text, slack_channel_id text, slack_thread_ts text, approved text)''')

        c.execute("INSERT INTO approvals VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                  (approval_request.request_id, approval_request.user_email, approval_request.purpose, approval_request.cost, approval_request.requested_at.isoformat(), approval_request.ttl, approval_request.expiry_time.isoformat(), approval_request.slack_channel_id, approval_request.slack_thread_ts, approval_request.approved))
        conn.commit()

        # Store tf_plan and cost_data in the database for later use
        c.execute('''CREATE TABLE IF NOT EXISTS tf_plans
                     (request_id text, tf_plan text, cost_data text)''')
        c.execute("INSERT INTO tf_plans VALUES (?, ?, ?)",
                  (request_id, tf_plan, json.dumps(cost_data)))
        conn.commit()
        conn.close()

        print("Approval request created successfully.")

    prompt = f"""
    You have a new infrastructure resources creation request from {USER_EMAIL} for the following purpose: {purpose}.
    Resource details: {resource_details}
    The estimated cost for the resource is: ${estimated_cost}.
    The ID of the request is {request_id}. Please ask the user if they would like to approve this request or not.
    """

    payload = {
        "agent_id": os.getenv('KUBIYA_AGENT_UUID'),
        "communication": {
            "destination": APPROVAL_SLACK_CHANNEL,
            "method": "Slack"
        },
        "created_at": datetime.utcnow().isoformat() + "Z",
        "created_by": USER_EMAIL,
        "name": "Approval Request",
        "org": KUBIYA_USER_ORG,
        "prompt": prompt,
        "source": "Triggered by an access request (Agent)",
        "updated_at": datetime.utcnow().isoformat() + "Z"
    }

    response = requests.post(
        "https://api.kubiya.ai/api/v1/event",
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'UserKey {KUBIYA_API_KEY}'
        },
        json=payload
    )

    if response.status_code < 300:
        print(f"Request submitted successfully and has been sent to an approver.")
        event_response = response.json()
        webhook_url = event_response.get("webhook_url")
        if webhook_url:
            webhook_response = requests.post(
                webhook_url,
                headers={'Content-Type': 'application/json'},
                json=payload
            )
            if webhook_response.status_code < 300:
                print("Webhook event sent successfully.")
            else:
                print(f"Error sending webhook event: {webhook_response.status_code} - {webhook_response.text}")
        else:
            print("Error: No webhook URL returned in the response. Could not send webhook to approving channel.")
    else:
        print(f"Error: {response.status_code} - {response.text}")

def manage_resource_request(user_input, purpose, ttl):
    try:
        # Step 1: Understand the request
        print("🔍 Understanding your request...")
        parsed_request, error_message = parse_user_request(user_input)

        if error_message:
            print(f"❌ {error_message}")
            return

        resource_details = parsed_request.resource_details
        # Generate request ID (UUID)
        request_id = uuid.uuid4().hex

        # Print request details
        print(f"📝 Created request entry with ID: {request_id}")

        # Step 2: Generate Terraform code
        print("🔧 Generating Terraform code for the specified resource...")
        tf_code_details = generate_terraform_code(resource_details)
        resource_details["tf_files"] = tf_code_details.tf_files
        resource_details["tf_code_explanation"] = tf_code_details.tf_code_explanation

        # Step 3: Attempt to create Terraform plan with retries
        print(f"🔧 Creating Terraform plan for the specified resource...")
        plan_success = False
        attempts = 0

        while not plan_success and attempts < MAX_TERRAFORM_RETRIES:
            attempts += 1
            print(f"Attempt {attempts}/{MAX_TERRAFORM_RETRIES} to create Terraform plan...")
            plan_success, plan_output_or_error, plan_json = create_terraform_plan(resource_details["tf_files"], request_id)

            if plan_success:
                print(f"✅ Terraform plan created successfully on attempt {attempts}\n\nHere is the plan:\n{plan_output_or_error}")
                break

            print(f"❌ Terraform plan failed on attempt {attempts}. Attempting to fix the code...")
            fixed_tf_code_details = fix_terraform_code(resource_details["tf_files"], plan_output_or_error)
            resource_details["tf_files"] = fixed_tf_code_details.tf_files
            resource_details["tf_code_explanation"] = fixed_tf_code_details.tf_code_explanation

        if not plan_success:
            print(f"❌ Terraform plan still failed after {MAX_TERRAFORM_RETRIES} attempts. Please contact your administrator.")
            return

        # Step 4: Estimate cost
        print(f"💰 Estimating costs for the specified resources...")
        estimation, cost_data = estimate_resource_cost(plan_json)
        slack_cost_data = format_cost_data_for_slack(cost_data)
        slack_msg = SlackMessage(os.getenv('SLACK_CHANNEL_ID'), os.getenv('SLACK_THREAD_TS'))
        slack_msg.send_block_message(slack_cost_data)
        print(f"💰 The estimated cost for this resources is ${estimation:.2f}.")

        # Step 5: Compare with average monthly cost
        print("📊 Comparing the estimated cost with the average monthly cost...")
        comparison_result = compare_cost_with_avg(estimation)
        average_monthly_cost = get_average_monthly_cost()

        if comparison_result == "greater":
            print(f"🔔 The estimated cost of ${estimation:.2f} exceeds the average monthly cost by more than 10% (Average: ${average_monthly_cost:.2f}).")
            if APPROVAL_WORKFLOW:
                print("🔔 Requesting approval for resources creation...")
                request_resource_creation_approval(request_id, purpose, resource_details, estimation, plan_json, cost_data, ttl, slack_msg.thread_ts)
                print("🔔 Approval request sent successfully.")
            else:
                print("⚠️ Approval workflow not enabled. Proceeding without approval but warning about the budget.")
                print(f"⚠️ Warning: Estimated cost ${estimation:.2f} exceeds the budget.")
                apply_resources(request_id, resource_details, resource_details["tf_files"], ttl)
        else:
            print(f"🚀 The estimated cost of ${estimation:.2f} is within the acceptable range (Average: ${average_monthly_cost:.2f}).")
            print("🚀 Attempting to create the resource(s)..")
            apply_resources(request_id, resource_details, resource_details["tf_files"], ttl)

    except Exception as e:
        print(f"❌ An error occurred: {e}")
        exit(1)

def apply_resources(request_id, resource_details, tf_files, ttl):
    if os.getenv('DRY_RUN_ENABLED'):
        print("🚀 Dry run mode enabled. Skipping Terraform apply.")
        apply_output, tf_state = apply_terraform(tf_files, request_id, apply=False)
    else:
        apply_output, tf_state = apply_terraform(tf_files, request_id, apply=True)

    # Check if the apply was successful
    if "Error" in apply_output or "error" in apply_output:
        print(f"❌ Terraform apply failed. Attempting to fix the code...")
        fixed_tf_code_details = fix_terraform_code(tf_files, apply_output)
        tf_files = fixed_tf_code_details.tf_files

        # Retry Terraform apply after fixing the code
        print("🚀 Retrying Terraform apply with fixed code...")
        apply_output, tf_state = apply_terraform(tf_files, request_id, apply=True)
        if "Error" in apply_output or "error" in apply_output:
            print(f"❌ Terraform apply failed again after fixing the code. Please contact your administrator.")
            return

    # Store the state in the database
    if STORE_STATE:
        print("📦 Attempting to store resources state")
        store_resource_in_db(request_id, resource_details, tf_state, ttl)
    # Schedule deletion task if TTL is enabled and state storage is enabled
    if TTL_ENABLED and STORE_STATE:
        print("⏰ Scheduling deletion task...")
        schedule_deletion_task(request_id, USER_EMAIL, ttl, SLACK_THREAD_TS)
    print(f"✅ All resources were successfully created. Terraform apply output:\n{apply_output}")

def store_resource_in_db(request_id, resource_details, tf_state, ttl):
    print("📦 Storing state")
    conn = sqlite3.connect('/sqlite_data/approval_requests.db')
    c = conn.cursor()

    ttl_seconds = timeparse(ttl)
    if ttl_seconds is None:
        error_message = "Invalid TTL format provided."
        print(f"❌ {error_message}")
        exit(1)

    expiry_time = datetime.utcnow() + timedelta(seconds=int(ttl_seconds))

    c.execute('''CREATE TABLE IF NOT EXISTS resources
                 (request_id text, resource_details text, tf_state text, expiry_time text)''')
    c.execute("INSERT INTO resources VALUES (?, ?, ?, ?)",
              (request_id, json.dumps(resource_details), tf_state, expiry_time.isoformat()))
    conn.commit()
    conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Manage infrastructure resources creation requests.')
    parser.add_argument('user_input', type=str, help='The natural language request from the user')
    parser.add_argument('--purpose', required=True, help='The purpose of the request')
    parser.add_argument('--ttl', default='1d', help='Time to live for the resource (e.g., 3h, 1d, 1m)')

    args = parser.parse_args()
    manage_resource_request(args.user_input, args.purpose, args.ttl)
