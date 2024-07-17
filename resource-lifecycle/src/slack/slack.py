import requests
import os

class SlackMessage:
    def __init__(self, channel, thread_ts=None):
        self.channel = channel or os.getenv('SLACK_CHANNEL_ID')
        self.thread_ts = os.getenv('SLACK_THREAD_TS') or thread_ts
        self.blocks = []
        self.api_key = os.getenv('SLACK_API_TOKEN')
        self.message_ts = None  # To store the timestamp of the message

    def send_initial_message(self, text):
        self.blocks = [
            {"type": "section", "text": {"type": "mrkdwn", "text": text}},
            {"type": "divider"}
        ]
        response = self.send_message()
        if response and 'ts' in response:
            self.message_ts = response['ts']

    def update_message(self, blocks):
        self.blocks = blocks
        self.send_message(update=True)

    def update_step(self, step_name, status, is_terraform=False):
        emoji = {
            "in_progress": "https://discuss.wxpython.org/uploads/default/original/2X/6/6d0ec30d8b8f77ab999f765edd8866e8a97d59a3.gif",
            "completed": "https://static-00.iconduck.com/assets.00/checkmark-running-icon-2048x2048-8081bf4v.png",
            "failed": "https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-512.png",
            "pending": ""
        }.get(status, "")

        if is_terraform:
            step_prefix = "https://static-00.iconduck.com/assets.00/terraform-icon-902x1024-397ze1ub.png"
        else:
            step_prefix = ""

        step_block = {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"{step_prefix} {emoji} *{step_name}*"}
        }

        # Update the existing step block if it exists, otherwise add a new one
        step_index = next((index for (index, d) in enumerate(self.blocks) if 'text' in d and f"*{step_name}*" in d["text"]["text"]), None)
        if step_index is not None:
            self.blocks[step_index] = step_block
        else:
            self.blocks.append(step_block)
            self.blocks.append({"type": "divider"})

        self.send_message(update=True)

    def send_block_message(self, blocks):
        self.blocks.extend(blocks)
        self.send_message(update=True)

    def send_message(self, update=False):
        if not self.api_key:
            if os.getenv('KUBIYA_DEBUG'):
                print("No SLACK_API_TOKEN set. Slack messages will not be sent.")
            return None

        payload = {
            "channel": self.channel,
            "blocks": self.blocks
        }
        if self.thread_ts:
            payload["thread_ts"] = self.thread_ts

        url = "https://slack.com/api/chat.postMessage"
        if update and self.message_ts:
            payload["ts"] = self.message_ts
            url = "https://slack.com/api/chat.update"

        response = requests.post(
            url,
            headers={
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {self.api_key}'
            },
            json=payload
        )
        if response.status_code >= 300:
            if os.getenv('KUBIYA_DEBUG'):
                print(f"Error sending Slack message: {response.status_code} - {response.text}")
        else:
            return response.json()
