#!/bin/bash
### Description: TTServer Media Automation Script
### Version: 1.1
### Original Authors: Nathan Taylor

### Custom Colors from Palette
pink='\033[38;2;255;0;255m'          # Hot Pink
purple='\033[38;2;128;0;128m'        # Purple
navy='\033[38;2;26;26;89m'           # Navy Blue
deep_blue='\033[38;2;0;0;255m'       # Deep Blue
cyan_blue='\033[38;2;0;170;255m'     # Bright Cyan Blue
reset='\033[0m'                      # Reset

scriptversion="1.1"
scriptdate="2024-11-21"

set -euo pipefail

### Ensure Script is Run as Root
if [ "$EUID" -ne 0 ]; then
    echo -e "${pink}Please run as root!${reset}"
    exit 1
fi

### Title Splash
echo -e "${purple}"
echo -e "#############################################################"
echo -e "#       c Script - Version $scriptversion      #"
echo -e "#                 Last Updated: $scriptdate                 #"
echo -e "#############################################################"
echo -e "${reset}"

### Prompt for Application to Install
echo "Select the application to install:"
echo ""
select app in radarr sonarr lidarr readarr prowlarr quit; do
    case $app in
    radarr)
        app_port="2405"
        app_prereq="curl sqlite3"
        branch="develop"
        break
        ;;
    sonarr)
        app_port="2406"
        app_prereq="curl sqlite3"
        branch="develop"
        break
        ;;
    lidarr)
        app_port="2407"
        app_prereq="curl sqlite3 libchromaprint-tools mediainfo"
        branch="develop"
        break
        ;;
    readarr)
        app_port="2408"
        app_prereq="curl sqlite3"
        branch="develop"
        break
        ;;
    prowlarr)
        app_port="2409"
        app_prereq="curl sqlite3"
        branch="develop"
        break
        ;;
    quit)
        exit 0
        ;;
    *)
        echo -e "${pink}Invalid option, please try again.${reset}"
        ;;
    esac
done
echo ""

### Constants
installdir="/nfserver/media-automation"
bindir="${installdir}/${app^}"
datadir="${bindir}/config"
app_user="ttserver"
app_group="ttserver"
app_bin="${app^}"

### Cleanup Partial Files on Failure
trap 'rm -rf /tmp/${app^}*; echo -e "${red}Script failed. Cleanup complete.${reset}"; exit 1' ERR

### Create User/Group if Needed
if ! getent group "$app_group" >/dev/null; then
    groupadd "$app_group"
fi
if ! getent passwd "$app_user" >/dev/null; then
    adduser --system --no-create-home --ingroup "$app_group" "$app_user"
fi
if ! getent group "$app_group" | grep -qw "$app_user"; then
    usermod -a -G "$app_group" "$app_user"
fi

### Stop Existing Service if Running
if service --status-all | grep -Fq "$app"; then
    systemctl stop "$app"
    systemctl disable "$app".service
fi

### Create Directories and Set Permissions
mkdir -p "$datadir" "$installdir"
chown -R "$app_user:$app_group" "$datadir" "$installdir"
chmod 750 "$datadir"
chmod 775 "$installdir"

### Install Required Packages
echo -e "${cyan_blue}Checking for missing prerequisite packages...${reset}"
missing_packages=()
for pkg in $app_prereq; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        missing_packages+=("$pkg")
    fi
done
if [ ${#missing_packages[@]} -gt 0 ]; then
    echo -e "Installing: ${deep_blue}${missing_packages[*]}${reset}"
    apt update && apt install -y "${missing_packages[@]}"
else
    echo -e "${green}All prerequisite packages are already installed!${reset}"
fi

### Download and Install the App
echo -e "${cyan_blue}Downloading and installing ${app^}...${reset}"
ARCH=$(dpkg --print-architecture)
dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
case "$ARCH" in
"amd64") DLURL="${dlbase}&arch=x64" ;;
"armhf") DLURL="${dlbase}&arch=arm" ;;
"arm64") DLURL="${dlbase}&arch=arm64" ;;
*)
    echo -e "${red}Unsupported architecture! Exiting.${reset}"
    exit 1
    ;;
esac
wget --content-disposition "$DLURL" -O "${app^}.tar.gz" || { echo "${red}Failed to download ${app^}.${reset}"; exit 1; }
tar -xvzf "${app^}.tar.gz" -C /tmp/
rm -rf "$bindir"
mv "/tmp/${app^}" "$bindir"
chown -R "$app_user:$app_group" "$bindir"
chmod 775 "$bindir"
rm "${app^}.tar.gz"

### Create Systemd Service File
echo -e "${cyan_blue}Setting up systemd service...${reset}"
cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
[Unit]
Description=${app^} Daemon
After=syslog.target network.target

[Service]
User=$app_user
Group=$app_group
UMask=0002
Type=simple
ExecStart=$bind
