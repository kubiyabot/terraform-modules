#!/bin/bash
if [ "${normalize_channel_name:-true}" = "true" ]; then 
    echo "${slack_channel_id}" | sed 's/ /_/g' | tr '[:upper:]' '[:lower:]'
else 
    echo "${slack_channel_id}" | tr '[:upper:]' '[:lower:]'
fi