import os
import argparse
import sqlite3
import uuid
import json
import requests
import signal
import sys
from datetime import datetime, timedelta
from pytimeparse.timeparse import timeparse
from pydantic import BaseModel, ValidationError
from litellm import completion
from models.models import ApprovalRequest
from slack.slack import SlackMessage
from llm.parse_request import parse_user_request, generate_terraform_code, fix_terraform_code
from iac.estimate_cost import estimate_resource_cost, format_cost_data_for_slack
from iac.compare_cost import compare_cost_with_avg, get_average_monthly_cost
from iac.terraform import apply_terraform, create_terraform_plan
from approval.scheduler import schedule_deletion_task
from llm.terraform_errors import is_error_unrecoverable

# Configuration from environment variables
MAX_CODE_GEN_RETRIES = int(os.getenv('MAX_CODE_GEN_RETRIES', 10))
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
UNRECOVERABLE_ERROR_CHECK = os.getenv('UNRECOVERABLE_ERROR_CHECK', 'true').lower() == 'true'

# Global variable to store the Slack message timestamp
SLACK_MESSAGE_TS = None

# Signal handler for termination signals
def signal_handler(sig, frame):
    global SLACK_MESSAGE_TS
    if SLACK_MESSAGE_TS:
        slack_msg = SlackMessage(SLACK_CHANNEL_ID, SLACK_THREAD_TS)
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "Resource Creation Progress"
                }
            },
            {
                "type": "divider"
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*ABORTED*"
                }
            }
        ]
        slack_msg.update_message(blocks)
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def update_slack_progress(slack_channel_id, thread_ts, task_statuses, initial=False):
    global SLACK_MESSAGE_TS
    slack_msg = SlackMessage(slack_channel_id, thread_ts)

    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "Resource Creation Progress"
            }
        },
        {
            "type": "divider"
        }
    ]

    for task, status in task_statuses.items():
        if status["is_terraform"]:
            prefix = ":terraform:"
        else:
            prefix = ""

        if status["status"] == "In Progress":
            status_emoji = ":hourglass_flowing_sand:"
        elif status.get("is_completed"):
            status_emoji = ":white_check_mark:"
        elif status.get("is_failed"):
            status_emoji = ":x:"
        else:
            status_emoji = ":hourglass:"

        task_block = {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"{prefix} *{task}*: {status_emoji} {status['status']}"}
        }

        blocks.append(task_block)

    if initial:
        slack_msg.send_initial_message(blocks)
    else:
        slack_msg.update_message(blocks)

def request_resource_creation_approval(request_id, purpose, resource_details, estimated_cost, tf_plan, cost_data, ttl, slack_thread_ts, task_statuses):
    requested_at = datetime.utcnow()

    ttl_seconds = timeparse(ttl)
    max_ttl_seconds = timeparse(MAX_TTL)

    if ttl_seconds is None or ttl_seconds > max_ttl_seconds:
        error_message = "TTL exceeds the maximum allowed TTL. Please adjust it to a lower value."
        print(f"❌ {error_message}")
        task_statuses["Requesting Approval"] = {"status": error_message, "is_terraform": False, "is_failed": True}
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
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

        c.execute('''CREATE TABLE IF NOT EXISTS tf_plans
                     (request_id text, tf_plan text, cost_data text)''')
        c.execute("INSERT INTO tf_plans VALUES (?, ?, ?)",
                  (request_id, tf_plan, json.dumps(cost_data)))
        conn.commit()
        conn.close()

        print("Approval request created successfully.")
        task_statuses["Requesting Approval"] = {"status": "Approval request created", "is_terraform": False, "is_completed": True}
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

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
        task_statuses["Requesting Approval"] = {"status": "Approval request sent to approver", "is_terraform": False, "is_completed": True}
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
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
                task_statuses["Requesting Approval"] = {"status": f"Error sending webhook event: {webhook_response.status_code} - {webhook_response.text}", "is_terraform": False, "is_failed": True}
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        else:
            print("Error: No webhook URL returned in the response. Could not send webhook to approving channel.")
            task_statuses["Requesting Approval"] = {"status": "No webhook URL returned", "is_terraform": False, "is_failed": True}
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
    else:
        print(f"Error: {response.status_code} - {response.text}")
        task_statuses["Requesting Approval"] = {"status": f"Error: {response.status_code} - {response.text}", "is_terraform": False, "is_failed": True}
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

def manage_resource_request(user_input, purpose, ttl):
    task_statuses = {
        "Understanding Request": {"status": "In Progress", "is_terraform": False},
        "Generating Terraform Code": {"status": "Pending", "is_terraform": True},
        "Creating Terraform Plan": {"status": "Pending", "is_terraform": True},
        "Estimating Costs": {"status": "Pending", "is_terraform": False},
        "Comparing Costs": {"status": "Pending", "is_terraform": False},
        "Requesting Approval": {"status": "Pending", "is_terraform": False},
        "Applying Terraform": {"status": "Pending", "is_terraform": True},
        "Storing State": {"status": "Pending", "is_terraform": False},
        "Scheduling Deletion Task": {"status": "Pending", "is_terraform": False}
    }

    # Remove "Requesting Approval" if approval workflow is not enabled
    if not APPROVAL_WORKFLOW:
        del task_statuses["Requesting Approval"]

    update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses, initial=True)

    try:
        print("🔍 Understanding your request...")
        parsed_request, error_message = parse_user_request(user_input)

        if error_message:
            print(f"Failed to parse request: {error_message}")
            task_statuses["Understanding Request"]["status"] = f"Failed: {error_message}"
            task_statuses["Understanding Request"]["is_failed"] = True
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            return

        resource_details = parsed_request.resource_details
        request_id = uuid.uuid4().hex

        print(f"📝 Created request entry with ID: {request_id}")
        task_statuses["Understanding Request"]["status"] = "Completed"
        task_statuses["Understanding Request"]["is_completed"] = True
        task_statuses["Generating Terraform Code"]["status"] = "In Progress"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

        retries = 0
        print("🧠 Generating Terraform code for the specified resource...")
        while retries < MAX_CODE_GEN_RETRIES:
            try:
                tf_code_details = generate_terraform_code(resource_details)
                resource_details["tf_files"] = tf_code_details.tf_files
                resource_details["tf_code_explanation"] = tf_code_details.tf_code_explanation
                task_statuses["Generating Terraform Code"]["status"] = "Completed"
                task_statuses["Generating Terraform Code"]["is_completed"] = True
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                break
            except Exception as e:
                retries += 1
                print(f"❌ Error generating Terraform code. Attempt {retries}/{MAX_CODE_GEN_RETRIES}. Error: {e}")
                task_statuses["Generating Terraform Code"]["status"] = f"Retrying ({retries}/{MAX_CODE_GEN_RETRIES})"
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                if retries == MAX_CODE_GEN_RETRIES:
                    print("❌ Failed to generate Terraform code after multiple attempts. Please contact your administrator.")
                    task_statuses["Generating Terraform Code"]["status"] = "Failed"
                    task_statuses["Generating Terraform Code"]["is_failed"] = True
                    update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                    return

        print(f"🌟📋 Creating Terraform plan for the specified resource...")
        task_statuses["Creating Terraform Plan"]["status"] = "In Progress"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        plan_success = False
        attempts = 0

        while not plan_success and attempts < MAX_TERRAFORM_RETRIES:
            attempts += 1
            print(f"Attempt {attempts}/{MAX_TERRAFORM_RETRIES} to create Terraform plan...")
            plan_success, plan_output_or_error, plan_json = create_terraform_plan(resource_details["tf_files"], request_id)

            if plan_success:
                print(f"✅ Terraform plan seems to be successful on attempt {attempts}.")
                task_statuses["Creating Terraform Plan"]["status"] = "Completed"
                task_statuses["Creating Terraform Plan"]["is_completed"] = True
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                break

            print(f"❌ Terraform plan failed on attempt {attempts}.")
            task_statuses["Creating Terraform Plan"]["status"] = f"Retrying ({attempts}/{MAX_TERRAFORM_RETRIES})"
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

            if UNRECOVERABLE_ERROR_CHECK:
                print("🧩 Checking if the error is unrecoverable...")
                try:
                    llm_response = is_error_unrecoverable(plan_output_or_error)
                    if llm_response.unrecoverable_error:
                        print(f"❌ Unrecoverable error detected: {llm_response.reasoning}")
                        print("Due to the following reasoning, we cannot proceed with the request:")
                        print(llm_response.reasoning)
                        task_statuses["Creating Terraform Plan"]["status"] = f"Unrecoverable error: {llm_response.reasoning}"
                        task_statuses["Creating Terraform Plan"]["is_failed"] = True
                        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                        return
                except Exception as e:
                    print(f"Failed to check if error is unrecoverable. Continuing with retry. Error: {e}")

            print("Attempting to fix the code...")
            task_statuses["Creating Terraform Plan"]["status"] = "Attempting to fix Terraform code..."
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            try:
                fixed_tf_code_details = fix_terraform_code(resource_details["tf_files"], plan_output_or_error)
                resource_details["tf_files"] = fixed_tf_code_details.tf_files
                resource_details["tf_code_explanation"] = fixed_tf_code_details.tf_code_explanation
            except Exception as e:
                print(f"Failed to fix Terraform code. Error: {e}")
                task_statuses["Creating Terraform Plan"]["status"] = f"Failed to fix Terraform code: {e}"
                task_statuses["Creating Terraform Plan"]["is_failed"] = True
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

        if not plan_success:
            print(f"❌ Terraform plan still failed after {MAX_TERRAFORM_RETRIES} attempts. Please contact your administrator.")
            task_statuses["Creating Terraform Plan"]["status"] = f"Failed after {MAX_TERRAFORM_RETRIES} attempts"
            task_statuses["Creating Terraform Plan"]["is_failed"] = True
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            return

        print(f"💰 Estimating costs for the specified resources...")
        task_statuses["Estimating Costs"]["status"] = "In Progress"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        estimation, cost_data = estimate_resource_cost(plan_json)
        slack_cost_data = format_cost_data_for_slack(cost_data)
        slack_msg = SlackMessage(os.getenv('SLACK_CHANNEL_ID'), os.getenv('SLACK_THREAD_TS'))
        slack_msg.send_block_message(slack_cost_data)
        print(f"💰 The estimated cost for this resources is ${estimation:.2f}.")
        task_statuses["Estimating Costs"]["status"] = f"Estimated cost: ${estimation:.2f}"
        task_statuses["Estimating Costs"]["is_completed"] = True
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

        print("📊 Comparing the estimated cost with the average monthly cost...")
        task_statuses["Comparing Costs"]["status"] = "In Progress"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        comparison_result = compare_cost_with_avg(estimation)
        average_monthly_cost = get_average_monthly_cost()

        if comparison_result == "greater":
            print(f"🔔 The estimated cost of ${estimation:.2f} exceeds the average monthly cost by more than 10% (Average: ${average_monthly_cost:.2f}).")
            task_statuses["Comparing Costs"]["status"] = f"Cost ${estimation:.2f} exceeds average (${average_monthly_cost:.2f})"
            task_statuses["Comparing Costs"]["is_warning"] = True
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            if APPROVAL_WORKFLOW:
                print("🔔 Requesting approval for resources creation...")
                task_statuses["Requesting Approval"]["status"] = "In Progress"
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                request_resource_creation_approval(request_id, purpose, resource_details, estimation, plan_json, cost_data, ttl, slack_msg.thread_ts, task_statuses)
                print("🔔 Approval request sent successfully.")
            else:
                print("⚠️ Approval workflow not enabled. Proceeding without approval but warning about the budget.")
                task_statuses["Comparing Costs"]["status"] = "Proceeding without approval (not enabled)"
                task_statuses["Comparing Costs"]["is_warning"] = True
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                print(f"⚠️ Warning: Estimated cost ${estimation:.2f} exceeds the budget.")
                apply_resources(request_id, resource_details, resource_details["tf_files"], ttl, task_statuses)
        else:
            print(f"🚀 The estimated cost of ${estimation:.2f} is within the acceptable range (Average: ${average_monthly_cost:.2f}).")
            task_statuses["Comparing Costs"]["status"] = f"Cost ${estimation:.2f} within acceptable range"
            task_statuses["Comparing Costs"]["is_completed"] = True
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            print("🚀 Attempting to create the resource(s)...")
            apply_resources(request_id, resource_details, resource_details["tf_files"], ttl, task_statuses)

    except Exception as e:
        print(f"Failed to complete the operation. Error: {e}")
        task_statuses["Understanding Request"]["status"] = f"Operation failed: {e}"
        task_statuses["Understanding Request"]["is_failed"] = True
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        print("This is most likely a problem with the tool implementation or the infrastructure it is running on. Please contact the operator who configured this tool.")
        exit(1)

def ttl_to_seconds(ttl, task_statuses):
    ttl_seconds = timeparse(ttl)
    if ttl_seconds is None:
        error_message = "Invalid TTL format provided."
        print(f"❌ {error_message}")
        task_statuses["Scheduling Deletion Task"] = {"status": error_message, "is_terraform": False, "is_failed": True}
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        exit(1)
    return int(ttl_seconds)

def apply_resources(request_id, resource_details, tf_files, ttl, task_statuses):
    max_apply_attempts = 3

    for attempt in range(max_apply_attempts):
        task_statuses["Applying Terraform"]["status"] = f"In Progress (Attempt {attempt + 1}/{max_apply_attempts})"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        if os.getenv('DRY_RUN_ENABLED'):
            print("🚀 Dry run mode enabled. Skipping Terraform apply.")
            apply_output, tf_state = apply_terraform(tf_files, request_id, apply=False)
        else:
            apply_output, tf_state = apply_terraform(tf_files, request_id, apply=True)

        if "Error" not in apply_output and "error" not in apply_output:
            task_statuses["Applying Terraform"]["status"] = "Terraform apply successful"
            task_statuses["Applying Terraform"]["is_completed"] = True
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            break

        print(f"Terraform apply failed on attempt {attempt + 1}/{max_apply_attempts}.")
        task_statuses["Applying Terraform"]["status"] = f"Failed (Attempt {attempt + 1}/{max_apply_attempts})"
        task_statuses["Applying Terraform"]["is_failed"] = True
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

        if UNRECOVERABLE_ERROR_CHECK:
            print("🧩 Checking if the error is unrecoverable...")
            task_statuses["Applying Terraform"]["status"] = "Checking for unrecoverable errors..."
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            try:
                llm_response = is_error_unrecoverable(apply_output)
                if llm_response.unrecoverable_error:
                    print(f"❌ Unrecoverable error detected during apply: {llm_response.reasoning}")
                    print("Due to the following reasoning, we cannot proceed with the request:")
                    print(llm_response.reasoning)
                    task_statuses["Applying Terraform"]["status"] = f"Unrecoverable error: {llm_response.reasoning}"
                    task_statuses["Applying Terraform"]["is_failed"] = True
                    update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
                    return
            except Exception as e:
                print(f"Failed to check if error is unrecoverable. Continuing with retry. Error: {e}")
                task_statuses["Applying Terraform"]["status"] = "Failed to check for unrecoverable errors"
                task_statuses["Applying Terraform"]["is_warning"] = True
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

        if attempt < max_apply_attempts - 1:
            print(f"Attempting to fix the code...")
            task_statuses["Applying Terraform"]["status"] = "Attempting to fix Terraform code..."
            update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
            try:
                fixed_tf_code_details = fix_terraform_code(tf_files, apply_output)
                tf_files = fixed_tf_code_details.tf_files
            except Exception as e:
                print(f"Failed to fix Terraform code. Error: {e}")
                task_statuses["Applying Terraform"]["status"] = f"Failed to fix Terraform code: {e}"
                task_statuses["Applying Terraform"]["is_failed"] = True
                update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
    else:
        print(f"Terraform apply failed after {max_apply_attempts} attempts. Please contact your administrator.")
        task_statuses["Applying Terraform"]["status"] = f"Failed after {max_apply_attempts} attempts"
        task_statuses["Applying Terraform"]["is_failed"] = True
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        return

    if STORE_STATE:
        print("📦 Attempting to store resources state")
        task_statuses["Storing State"]["status"] = "In Progress"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        store_resource_in_db(request_id, resource_details, tf_state, ttl, task_statuses)
    
    if TTL_ENABLED and STORE_STATE:
        print("⏰ Scheduling deletion task...")
        task_statuses["Scheduling Deletion Task"]["status"] = "In Progress"
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        ttl_seconds = ttl_to_seconds(ttl, task_statuses)
        schedule_deletion_task(request_id, ttl_seconds, SLACK_THREAD_TS)
    
    print(f"✅ All resources were successfully created! Request will be deleted after the TTL expires.")
    task_statuses["Scheduling Deletion Task"]["status"] = "Resources created successfully"
    task_statuses["Scheduling Deletion Task"]["is_completed"] = True
    update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
    task_statuses["Completed"] = {"status": "All operations were completed successfully! 🎉", "is_terraform": False, "is_completed": True}
    update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

def store_resource_in_db(request_id, resource_details, tf_state, ttl, task_statuses):
    print("📦 Storing state")
    conn = sqlite3.connect('/sqlite_data/approval_requests.db')
    c = conn.cursor()

    ttl_seconds = timeparse(ttl)
    if ttl_seconds is None:
        error_message = "Invalid TTL format provided."
        print(f"❌ {error_message}")
        task_statuses["Storing State"] = {"status": error_message, "is_terraform": False, "is_failed": True}
        update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)
        exit(1)

    expiry_time = datetime.utcnow() + timedelta(seconds=int(ttl_seconds))

    c.execute('''CREATE TABLE IF NOT EXISTS resources
                 (request_id text, resource_details text, tf_state text, expiry_time text)''')
    c.execute("INSERT INTO resources VALUES (?, ?, ?, ?)",
              (request_id, json.dumps(resource_details), tf_state, expiry_time.isoformat()))
    conn.commit()
    conn.close()
    task_statuses["Storing State"] = {"status": "Resource state stored in database", "is_terraform": False, "is_completed": True}
    update_slack_progress(SLACK_CHANNEL_ID, SLACK_THREAD_TS, task_statuses)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Manage infrastructure resources creation requests.')
    parser.add_argument('user_input', type=str, help='The natural language request from the user')
    parser.add_argument('--purpose', required=True, help='The purpose of the request')
    parser.add_argument('--ttl', default='1d', help='Time to live for the resource (e.g., 3h, 1d, 1m)')

    args = parser.parse_args()
    manage_resource_request(args.user_input, args.purpose, args.ttl)
