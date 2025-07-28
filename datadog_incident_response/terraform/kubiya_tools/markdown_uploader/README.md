# Investigation Markdown Reporter Tool

## Description
A Kubiya tool that processes incident investigation results and posts them to Slack with proper formatting.

## Files
- `tool_definition.json` - Tool specification and argument definitions
- `upload_results.py` - Python script that handles Slack posting
- `README.md` - This documentation

## Functionality
1. Receives investigation results from workflow steps
2. Formats incident information for Slack presentation
3. Posts complete investigation results in code blocks
4. Includes interactive button for follow-up investigation
5. Handles both successful and failed scenarios gracefully

## Arguments
- **Required**: `slack_token`, `channel`, `incident_id`, `incident_severity`, `affected_services`
- **Optional**: `incident_title`, `executive_summary`, `cluster_results`, `agent_uuid`, `investigator_interactive_prompt`, `region`, `dd_environment`, `k8s_environment`

## Output Format
Posts a single Slack message containing:
- Incident metadata (ID, title, severity, region, services)
- Executive summary in code block
- Technical investigation results in code block  
- Interactive button for continued investigation
- Timestamp and completion status

## Error Handling
- Multiple retry attempts (3x) with exponential backoff
- Fallback from rich blocks to plain text if formatting fails
- Comprehensive logging for debugging
- Graceful degradation when components fail