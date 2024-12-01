#!/bin/bash

# Array of source folders
folders=(
    "/nfserver/Docker/media-grabbers/lidarr/Backups/scheduled/"
    "/nfserver/Docker/media-grabbers/radarr/Backups/scheduled/"
    "/nfserver/Docker/media-grabbers/readarr/Backups/scheduled/"
    "/nfserver/Docker/media-grabbers/sonarr/Backups/scheduled/"
)

# Destination folder for local backups (also the GitHub repository folder)
github_repo_folder="/nfserver/media-automation-backups/git"
backups_folder="$github_repo_folder/backups"

# GitHub repository URL
github_repo_url="https://github.com/taylorn84/TTServer.git"

# Ensure the backups folder exists
mkdir -p "$backups_folder"

# Check if the GitHub repository is initialized
if [[ ! -d "$github_repo_folder/.git" ]]; then
    echo "GitHub repository not found. Cloning repository..."
    git clone "$github_repo_url" "$github_repo_folder"
else
    echo "GitHub repository already exists. Pulling latest changes..."
    cd "$github_repo_folder" || exit
    git pull origin main
fi

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
            # Copy the file to the backups folder
            cp -f "$newest_file" "$backups_folder/$new_filename"
            echo "Copied $newest_file to the GitHub backups folder as $new_filename"
        else
            echo "No files found in $folder"
        fi
    else
        echo "Folder $folder does not exist"
    fi
done

# Add, commit, and push changes to GitHub
cd "$github_repo_folder" || exit
git add backups/
git commit -m "Updated backup files $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main
