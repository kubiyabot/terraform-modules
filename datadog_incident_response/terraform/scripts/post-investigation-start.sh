#!/bin/bash
echo 'WORKFLOW STARTED - posting start message'
echo 'DEBUG: Raw channel = '${slack_channel_id}
echo 'DEBUG: Normalized channel = '${NORMALIZED_CHANNEL_NAME}
echo 'DEBUG: Incident ID = '${incident_id}
echo 'DEBUG: Token exists = '$([ -n "${slack_token.token}" ] && echo 'YES' || echo 'NO')

if [ -z "${slack_token.token}" ] || [ "${slack_token.token}" = "null" ]; then 
    echo 'ERROR: No Slack token available - exiting'
    exit 0
fi

echo 'Slack token available, posting message to '${NORMALIZED_CHANNEL_NAME}'...'

RESPONSE=$(curl -s -X POST https://slack.com/api/chat.postMessage \
    -H "Authorization: Bearer ${slack_token.token}" \
    -H "Content-Type: application/json" \
    -d "{\"channel\":\"${NORMALIZED_CHANNEL_NAME}\",\"text\":\"🚀 WORKFLOW STARTED: AI investigation started for incident ${incident_id}: ${incident_title} (Severity: ${incident_severity})\"}")

echo 'Slack API Response: '$RESPONSE
echo 'Start notification step completed'