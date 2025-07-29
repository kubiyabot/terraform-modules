#!/bin/bash
echo '🔍 PREPARING INVESTIGATOR AGENT INTERACTIVE PROMPT'
echo '==============================================='

REGION_UPPER=$(echo '${REGION}' | tr '[:lower:]' '[:upper:]')
REGION_LOWER=$(echo '${REGION}' | tr '[:upper:]' '[:lower:]')

INVESTIGATOR_INTERACTIVE_PROMPT="You are an INCIDENT RESPONDER AGENT focusing on $REGION_UPPER PRODUCTION. INCIDENT: ${incident_id} - ${incident_title}. Region: $REGION_UPPER. Environment: ${dd_environment}. I have access to kubectl (${k8s_environment} cluster) and monitoring tools. Let me gather $REGION_LOWER-specific logs and metrics first... What aspect of the $REGION_UPPER cluster would you like me to investigate?"

echo "INVESTIGATOR_INTERACTIVE_PROMPT=$INVESTIGATOR_INTERACTIVE_PROMPT"
echo '✅ Investigator interactive prompt prepared successfully'