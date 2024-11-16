#!/bin/bash

# Redirect all output to a log file for troubleshooting
exec > >(tee -i setup.log)
exec 2>&1

# Variables
COCKPIT_PORT=2400
NETPLAN_CONFIG="/etc/netplan/00-installer-config.yaml"
SAMBA_CONFIG="/etc/samba/smb.conf"
COCKPIT_CONFIG_DIR="/etc/systemd/system/cockpit.socket.d"
COCKPIT_CONFIG_FILE="$COCKPIT_CONFIG_DIR/listen.conf"
TTUSER="ttserver"
TTPASS="PenelopeTT2901"
GATEWAY="192.168.31.1"
NAMESERVERS="[8.8.8.8,8.8.4.4,192.168.31.1]"

# Helper function for error handling
check_command() {
    if ! "$@"; then
        echo "Error: Command failed - $*"
        exit 1
    fi
}

# Update package list and install Cockpit if not already installed
if ! command -v cockpit &> /dev/null; then
    echo "Installing Cockpit..."
    check_command sudo apt-get update
    check_command sudo apt-get install -y cockpit
else
    echo "Cockpit is already installed."
fi

# Enable and start Cockpit service
if ! sudo systemctl is-enabled --quiet cockpit.socket; then
    echo "Enabling and starting Cockpit service..."
    check_command sudo systemctl enable --now cockpit.socket
else
    echo "Cockpit service is already enabled and running."
fi

# Set up Cockpit to listen on a custom port
if [ ! -f "$COCKPIT_CONFIG_FILE" ]; then
    echo "Setting custom port for Cockpit..."
    check_command sudo mkdir -p "$COCKPIT_CONFIG_DIR"
    check_command sudo bash -c 'cat > '"$COCKPIT_CONFIG_FILE"' << EOF
[Socket]
ListenStream=
ListenStream='"$COCKPIT_PORT"'
EOF'
    check_command sudo systemctl daemon-reload
    check_command sudo systemctl restart cockpit.socket
else
    echo "Cockpit custom port configuration already exists."
fi

# Configure Netplan network settings
if [ ! -f "$NETPLAN_CONFIG" ]; then
    echo "Configuring network settings with Netplan..."
    check_command sudo bash -c 'cat > '"$NETPLAN_CONFIG"' << EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    esp4s0:
      dhcp4: false
      dhcp6: false
      routes:
        - to: default
          via: '"$GATEWAY"'
      nameservers:
        addresses: '"$NAMESERVERS"'
EOF'
    check_command sudo netplan try
else
    echo "Netplan configuration already exists."
fi

# Add 45Drives repository
if ! grep -q "repo.45drives.com" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo "Adding 45Drives repository and updating..."
    check_command curl -sSL https://repo.45drives.com/setup | sudo bash
    check_command sudo apt-get update
else
    echo "45Drives repository already added."
fi

# Install additional Cockpit modules
if ! dpkg -l | grep -q "cockpit-file-sharing"; then
    echo "Installing Cockpit modules..."
    check_command sudo apt install -y cockpit-file-sharing cockpit-navigator
else
    echo "Cockpit modules are already installed."
fi

# Create directory /ttserver
if [ ! -d "/ttserver" ]; then
    echo "Creating /ttserver directory and setting ownership..."
    check_command sudo mkdir -p /ttserver
    check_command sudo chown -R "$TTUSER":"$TTUSER" /ttserver
else
    echo "/ttserver directory already exists."
fi

# Install Samba
if ! command -v smbd &> /dev/null; then
    echo "Installing Samba..."
    check_command sudo apt install -y samba
else
    echo "Samba is already installed."
fi

# Create Samba user
if ! sudo pdbedit -L | grep -q "$TTUSER"; then
    echo "Creating Samba user '$TTUSER' with password..."
    (echo "$TTPASS"; echo "$TTPASS") | check_command sudo smbpasswd -a "$TTUSER"
else
    echo "Samba user '$TTUSER' already exists."
fi

# Configure Samba share
if ! grep -q "\[TTServer\]" "$SAMBA_CONFIG"; then
    echo "Configuring Samba share..."
    check_command sudo mkdir -p /home/"$TTUSER"
    check_command sudo bash -c 'cat >> '"$SAMBA_CONFIG"' << EOF

[TTServer]
  path = /home/'"$TTUSER"'
  read only = no
  inherit permissions = yes
EOF'
    check_command sudo systemctl restart smbd
else
    echo "Samba share configuration already exists."
fi

# Install additional dependencies for Cockpit-Docker
echo "Installing dependencies for Cockpit-Docker..."
check_command sudo apt install -y gettext nodejs make

# Clone and install Cockpit-Docker
if [ ! -d "cockpit-docker" ]; then
    echo "Cloning and installing Cockpit-Docker..."
    check_command git clone https://github.com/cockpit-docker/cockpit-docker
    check_command cd cockpit-docker
    check_command make
    check_command sudo make install
    check_command cd ..
    check_command rm -rf cockpit-docker
else
    echo "Cockpit-Docker is already installed."
fi

echo "Setup completed successfully!"
