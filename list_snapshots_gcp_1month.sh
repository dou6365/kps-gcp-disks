#!/bin/bash

# Set your project ID here
PROJECT_ID="kr-4315-ks-s"

# Define the date one month ago (compatible with macOS)
ONE_MONTH_AGO=$(date -v-1m +%s)

# Get the list of snapshots older than one month

OLD_SNAPSHOTS=$(gcloud compute snapshots list --project="$PROJECT_ID" --format="json" | jq -r --arg one_month_ago "$ONE_MONTH_AGO" '
    [.[] |
    select(.creationTimestamp != null) |
    .creationTimestamp as $creation |
    # Remove timezone offset from timestamp if present
    ($creation | sub("\\.[0-9]+-[0-9]{2}:[0-9]{2}$"; "Z") | fromdateiso8601) as $creation_seconds |
    select($creation_seconds < ($one_month_ago | tonumber)) |
    {name: .name, creationTimestamp: .creationTimestamp}]
')

# Display each snapshot with name and timestamp
echo "Snapshots older than 1 month:"
echo "$OLD_SNAPSHOTS" | jq -c '.[]'

# Count and display the total
TOTAL_COUNT=$(echo "$OLD_SNAPSHOTS" | jq length)
echo "Total snapshots older than 1 month: $TOTAL_COUNT"
