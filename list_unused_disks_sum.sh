#!/bin/bash

# Check if the project ID is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <project-id>"
  exit 1
fi

# Set the project ID from the first argument
PROJECT_ID="$1"

# Set the project in gcloud
gcloud config set project $PROJECT_ID

# Fetch all disks in the project and filter those that are not attached
unused_disks=$(gcloud compute disks list --filter="-users:*" --format="value(name,zone,sizeGb)")

# Initialize counters
total_disks=0
total_size=0

# Output the unused disks
if [ -z "$unused_disks" ]; then
  echo "No unused disks found in project $PROJECT_ID."
else
  echo "Unused disks in project $PROJECT_ID:"
  printf "%-20s %-20s %-10s\n" "NAME" "ZONE" "SIZE_GB"
  printf "%-20s %-20s %-10s\n" "----" "----" "-------"

  while IFS= read -r disk; do
    # Using awk to handle the case where the zone might be missing
    disk_name=$(echo $disk | awk '{print $1}')
    disk_size=$(echo $disk | awk '{print $NF}')  # The size is always the last field
    disk_zone=$(echo $disk | awk '{print $(NF-1)}')  # The zone is the second to last field

    # If the zone is not defined, assume "NotDefined"
    if [[ "$disk_zone" =~ ^[0-9]+$ ]]; then
      disk_zone="NotDefined"
    fi

    printf "%-20s %-20s %-10s\n" "$disk_name" "$disk_zone" "$disk_size"

    # Increment counters
    total_disks=$((total_disks + 1))
    total_size=$((total_size + disk_size))
  done <<< "$unused_disks"

  # Print the total row
  echo
  echo "Total unused disks: $total_disks"
  echo "Total unused storage: ${total_size} GB"
fi

 #Cost per Zonal SSD: $0.204 FMI https://cloud.google.com/compute/disks-image-pricing#persistentdisk
 costSSD=0.048
 result=$(echo "$total_size * $costSSD" |bc)

 #Print the result
 echo "You are saving: $result if you decide to remove all these unused disks"
