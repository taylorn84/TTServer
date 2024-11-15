#!/bin/bash

# Update package list and install Cockpit if not already installed
if ! command -v cockpit &> /dev/null; then
    echo "Installing Cockpit..."
    sudo apt-get update
    sudo apt-get install -y cockpit
else
    echo "Cockpit is already installed."
fi

# Enable and start Cockpit service if not already enabled
if ! sudo systemctl is-enabled --quiet cockpit.socket; then
    echo "Enabling and starting Cockpit service..."
    sudo systemctl enable --now cockpit.socket
else
    echo "Cockpit service is already enabled and running."
fi

# Set up Cockpit to listen on a custom port if configuration does not exist
COCKPIT_CONFIG_DIR="/etc/systemd/system/cockpit.socket.d"
COCKPIT_CONFIG_FILE="$COCKPIT_CONFIG_DIR/listen.conf"
if [ ! -f "$COCKPIT_CONFIG_FILE" ]; then
    echo "Setting custom port for Cockpit..."
    sudo mkdir -p "$COCKPIT_CONFIG_DIR"
    sudo bash -c 'cat > '"$COCKPIT_CONFIG_FILE"' << EOF
[Socket]
ListenStream=
ListenStream=2400
EOF'
    sudo systemctl daemon-reload
    sudo systemctl restart cockpit.socket
else
    echo "Cockpit custom port configuration already exists."
fi

# Configure Netplan network settings if configuration file does not exist
NETPLAN_CONFIG="/etc/netplan/00-installer-config.yaml"
if [ ! -f "$NETPLAN_CONFIG" ]; then
    echo "Configuring network settings with Netplan..."
    sudo bash -c 'cat > '"$NETPLAN_CONFIG"' << EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    esp4s0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.31.24/24
      routes:
        - to: default
          via: 192.168.31.1
      nameservers:
        addresses: [8.8.8.8,8.8.4.4,192.168.31.1]
EOF'
    sudo netplan try
else
    echo "Netplan configuration already exists."
fi

# Add 45Drives repository and update package list if not already done
if ! grep -q "repo.45drives.com" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo "Adding 45Drives repository and updating..."
    curl -sSL https://repo.45drives.com/setup | sudo bash
    sudo apt-get update
else
    echo "45Drives repository already added."
fi

# Install additional Cockpit modules if not already installed
if ! dpkg -l | grep -q "cockpit-file-sharing"; then
    echo "Installing Cockpit modules..."
    sudo apt install -y cockpit-file-sharing cockpit-navigator
else
    echo "Cockpit modules are already installed."
fi

# Create directory /ttserver if not already created
if [ ! -d "/ttserver" ]; then
    echo "Creating /ttserver directory and setting ownership..."
    sudo mkdir -p /ttserver
    sudo chown -R ttserver:ttserver /ttserver
else
    echo "/ttserver directory already exists."
fi

# Install Samba if not already installed
if ! command -v smbd &> /dev/null; then
    echo "Installing Samba..."
    sudo apt install -y samba
else
    echo "Samba is already installed."
fi

# Create Samba user 'nfserver' with specific password if user does not exist
if ! sudo pdbedit -L | grep -q "nfserver"; then
    echo "Creating Samba user 'nfserver' with password 'PenelopeTT2901'..."
    (echo "PenelopeTT2901"; echo "PenelopeTT2901") | sudo smbpasswd -a nfserver
else
    echo "Samba user 'nfserver' already exists."
fi

# Configure Samba to share /nfserver if not already configured
SAMBA_CONFIG="/etc/samba/smb.conf"
if ! grep -q "\[NFServer\]" "$SAMBA_CONFIG"; then
    echo "Configuring Samba share..."
    sudo mkdir -p /nfserver
    sudo bash -c 'cat >> '"$SAMBA_CONFIG"' << EOF

[NFServer]
  path = /nfserver
  read only = no
  inherit permissions = yes
EOF'
    sudo systemctl restart smbd
else
    echo "Samba share configuration already exists."
fi

echo "Setup completed successfully!"
