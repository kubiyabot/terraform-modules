import os
import sys
from datetime import datetime, timedelta
import requests
from slack.slack import SlackMessage

def schedule_deletion_task(request_id, user_email, ttl, slack_thread_ts):
    schedule_time = (datetime.utcnow() + timedelta(seconds=ttl)).isoformat()

    task_payload = {
        "schedule_time": schedule_time,
        "task_description": f"Delete resources associated with request ID {request_id} as the TTL has expired.",
        "channel_id": os.getenv('APPROVAL_SLACK_CHANNEL'),
        "user_email": user_email,
        "organization_name": os.getenv("KUBIYA_USER_ORG"),
        "agent": os.getenv("KUBIYA_AGENT_PROFILE"),
        "thread_ts": slack_thread_ts,
        "request_id": request_id
    }

    response = requests.post(
        'https://api.kubiya.ai/api/v1/scheduled_tasks',
        headers={
            'Authorization': f'UserKey {os.getenv("KUBIYA_API_KEY")}',
            'Content-Type': 'application/json'
        },
        json=task_payload
    )

    if response.status_code >= 300:
        slack_msg = SlackMessage(os.getenv('APPROVAL_SLACK_CHANNEL'))
        slack_msg.update_message(f"❌ Error scheduling task for request ID {request_id}: {response.status_code} - {response.text}")
        print(f"Error scheduling task: {response.status_code} - {response.text}")
        sys.exit(1)