#!/bin/bash

# Array of source folders
folders=(
    "/nfserver/Docker/media-grabbers/lidarr/Backups/scheduled/"
    "/nfserver/Docker/media-grabbers/radarr/Backups/scheduled/"
    "/nfserver/Docker/media-grabbers/readarr/Backups/scheduled/"
    "/nfserver/Docker/media-grabbers/sonarr/Backups/scheduled/"
)

# Destination folder
destination_folder="/nfserver/media-automation-backups/"

# Ensure the destination folder exists
mkdir -p "$destination_folder"

# Iterate over each folder
for folder in "${folders[@]}"; do
    if [[ -d "$folder" ]]; then
        # Find the newest file in the folder
        newest_file=$(find "$folder" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

        if [[ -n "$newest_file" ]]; then
            # Get the name of the folder two levels up
            folder_name=$(basename "$(dirname "$(dirname "$folder")")")
            # Construct the new filename
            new_filename="${folder_name}-backup.zip"
            # Full destination path
            destination_path="$destination_folder/$new_filename"
            # Move the file and overwrite the existing one
            mv -f "$newest_file" "$destination_path"
            echo "Moved and renamed $newest_file to $destination_path"
        else
            echo "No files found in $folder"
        fi
    else
        echo "Folder $folder does not exist"
    fi
done
