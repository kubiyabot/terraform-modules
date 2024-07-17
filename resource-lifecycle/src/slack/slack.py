import requests
import os

class SlackMessage:
    def __init__(self, channel=None, thread_ts=None):
        self.channel = channel or os.getenv('SLACK_CHANNEL_ID')
        self.thread_ts = os.getenv('SLACK_THREAD_TS') or thread_ts
        self.blocks = []
        self.api_key = os.getenv('SLACK_API_TOKEN')

    def send_initial_message(self, steps):
        self.blocks = []
        for step in steps:
            elements = [
                {
                    "type": "image",
                    "image_url": step["icon"],
                    "alt_text": step["name"]
                },
                {
                    "type": "mrkdwn",
                    "text": f"*{step['name']}*"
                },
                {
                    "type": "image",
                    "image_url": "https://discuss.wxpython.org/uploads/default/original/2X/6/6d0ec30d8b8f77ab999f765edd8866e8a97d59a3.gif",
                    "alt_text": "progress"
                }
            ]
            self.blocks.append({"type": "context", "elements": elements})
        self.blocks.append({"type": "divider"})
        self.send_message()

    def update_step(self, step_name, status):
        emoji = {
            "in_progress": ":hourglass_flowing_sand:",
            "completed": ":white_check_mark:",
            "failed": ":x:",
            "waiting": ":hourglass:"
        }.get(status, "")

        step_block = {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"{emoji} *{step_name}*"}
        }

        step_index = next((index for (index, d) in enumerate(self.blocks) if d["type"] == "section" and f"*{step_name}*" in d["text"]["text"]), None)
        if step_index is not None:
            self.blocks[step_index] = step_block
        else:
            self.blocks.append(step_block)
            self.blocks.append({"type": "divider"})

        self.send_message()

    def send_block_message(self, blocks):
        self.blocks.extend(blocks)
        self.send_message()

    def send_message(self, text=None):
        if not self.api_key:
            if os.getenv('KUBIYA_DEBUG'):
                print("No SLACK_API_TOKEN set. Slack messages will not be sent.")
            return
        payload = {
            "channel": self.channel,
            "blocks": self.blocks
        }
        if self.thread_ts:
            payload["thread_ts"] = self.thread_ts
        response = requests.post(
            "https://slack.com/api/chat.postMessage",
            headers={
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {self.api_key}'
            },
            json=payload
        )
        if response.status_code >= 300:
            if os.getenv('KUBIYA_DEBUG'):
                print(f"Error sending Slack message: {response.status_code} - {response.text}")
