#!/usr/bin/env python3
import os
import json
import requests
from datetime import datetime

def safe_post_slack_message(token, channel_name, incident_info, summary, results, upload_status, button_config):
    """Send plain Slack message with all investigation results in code blocks"""
    max_retries = 3
    retry_delay = 2
    
    for attempt in range(max_retries):
        try:
            print(f'📡 ATTEMPT {attempt + 1}/{max_retries}: Posting plain message to Slack...')
            
            headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
            timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
            
            # Create comprehensive plain text message with code blocks
            status_indicator = '⚠️ (FILE UPLOAD FAILED)' if upload_status['failed'] else '✅'
            
            # Build the complete message with all investigation results
            message_text = f"""{status_indicator} **AI INVESTIGATION COMPLETE**

**Incident:** {incident_info['id']} - {incident_info['title']}
**Severity:** {incident_info['severity']} | **Region:** {incident_info['region']} | **Services:** {incident_info['services']}
**Completed:** {timestamp}

---

**📊 EXECUTIVE SUMMARY:**
```
{summary}
```

**🔍 TECHNICAL INVESTIGATION RESULTS:**
```
{results}
```

---

🔍 **Need more investigation?** Use the investigation button below to continue analyzing specific findings.

_Investigation completed by Kubiya AI-powered incident response system_"""
            
            # Create payload with button for further investigation
            payload = {
                'channel': channel_name,
                'text': message_text,
                'blocks': [
                    {
                        'type': 'section',
                        'text': {
                            'type': 'mrkdwn',
                            'text': message_text
                        }
                    },
                    {
                        'type': 'actions',
                        'elements': [
                            {
                                'type': 'button',
                                'text': {
                                    'type': 'plain_text',
                                    'text': f'🔍 Continue Investigation ({incident_info["region"].upper()})',
                                    'emoji': True
                                },
                                'style': 'primary',
                                'value': json.dumps(button_config),
                                'action_id': 'agent.process_message_1'
                            }
                        ]
                    }
                ]
            }
            
            print(f'📡 Posting complete investigation message...')
            response = requests.post('https://slack.com/api/chat.postMessage', 
                                   headers=headers, json=payload, timeout=20)
            
            print(f'📊 Response status: {response.status_code}')
            print(f'📝 Response content: {response.text[:500]}...')
            
            if response.status_code == 200:
                result = response.json()
                if result.get('ok'):
                    print('✅ SUCCESS: Complete investigation message posted to Slack!')
                    print(f'📍 Message posted to channel: {channel_name}')
                    return True
                else:
                    error_msg = result.get('error', 'Unknown error')
                    print(f'❌ Slack API error: {error_msg}')
                    
                    # If it's a formatting issue, try without blocks
                    if 'invalid_blocks' in error_msg or 'block' in error_msg.lower():
                        print('🔄 Retrying without blocks (plain text only)...')
                        simple_payload = {
                            'channel': channel_name,
                            'text': message_text
                        }
                        
                        response = requests.post('https://slack.com/api/chat.postMessage', 
                                               headers=headers, json=simple_payload, timeout=15)
                        
                        if response.status_code == 200 and response.json().get('ok'):
                            print('✅ SUCCESS: Plain text message posted to Slack!')
                            return True
            else:
                print(f'❌ HTTP error: {response.status_code}')
            
            # Retry logic
            print(f'⚠️ Attempt {attempt + 1} failed, retrying in {retry_delay} seconds...')
            if attempt < max_retries - 1:
                import time
                time.sleep(retry_delay)
                
        except Exception as e:
            print(f'❌ Attempt {attempt + 1} failed with exception: {e}')
            if attempt < max_retries - 1:
                import time
                time.sleep(retry_delay)
    
    print('❌ ALL ATTEMPTS FAILED - Could not post to Slack after 3 retries')
    return False

def main():
    # Get environment variables
    slack_token = os.getenv('slack_token')
    channel = os.getenv('channel')
    incident_id = os.getenv('incident_id')
    incident_title = os.getenv('incident_title')
    incident_severity = os.getenv('incident_severity')
    affected_services = os.getenv('affected_services')
    agent_uuid = os.getenv('agent_uuid', '2e5681c4-e4cd-43fe-8d5d-2f14216adf92')
    region = os.getenv('region', 'unknown')
    dd_environment = os.getenv('dd_environment', 'production')
    
    executive_summary_text = os.getenv('executive_summary', 'Executive summary generation failed - agent may have timed out or encountered an error. Please review the cluster investigation results below for technical details.')
    cluster_results = os.getenv('cluster_results', 'No cluster investigation results available - agent may have failed or timed out.')
    investigator_prompt_output = os.getenv('investigator_interactive_prompt', '')
    
    print(f'🔄 Processing investigation results for incident {incident_id}')
    
    # Prepare investigation prompt for follow-up
    investigation_prompt = f'Continue investigating incident {incident_id} in {region.upper()} production. Use kubectl and monitoring tools to dig deeper into specific findings from the initial analysis. What would you like me to investigate further?'
    
    # Try to extract INVESTIGATOR_INTERACTIVE_PROMPT from the output
    import re
    if investigator_prompt_output:
        match = re.search(r'INVESTIGATOR_INTERACTIVE_PROMPT=(.+)', investigator_prompt_output)
        if match:
            investigation_prompt = match.group(1).strip()
    
    print('🚀 STARTING SLACK MESSAGE POSTING...')
    print(f'🔍 Slack token status: {"Available" if slack_token and slack_token != "null" else "Missing"}')
    print(f'📋 Channel: {channel}')
    print(f'📊 Executive summary length: {len(executive_summary_text)}')
    print(f'🔧 Cluster results length: {len(cluster_results)}')
    
    # Only attempt Slack posting if we have a token
    if slack_token and slack_token != 'null' and slack_token.strip():
        print('🚀 INITIATING SLACK MESSAGE POSTING...')
        
        incident_info = {
            'id': incident_id or 'unknown',
            'title': incident_title or 'Unknown Incident',
            'severity': incident_severity or 'unknown',
            'services': affected_services or 'unknown',
            'region': region or 'unknown'
        }
        
        upload_status = {'failed': False}  # No file upload in this version
        
        button_config = {
            'agent_uuid': agent_uuid,
            'message': investigation_prompt
        }
        
        success = safe_post_slack_message(
            slack_token, channel, incident_info, 
            executive_summary_text, cluster_results, 
            upload_status, button_config
        )
        
        if success:
            print('🎉 SLACK MESSAGE POSTED SUCCESSFULLY!')
        else:
            print('💥 CRITICAL: Could not post to Slack despite all attempts')
    else:
        print('❌ SKIP: No valid Slack token available for message posting')
    
    print('🎉 Investigation report processing completed!')

if __name__ == '__main__':
    main()