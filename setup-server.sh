#!/bin/bash

# Update package list and install Cockpit
echo "Installing Cockpit..."
sudo apt-get update
sudo apt-get install -y cockpit

# Enable and start Cockpit service
echo "Enabling and starting Cockpit service..."
sudo systemctl enable --now cockpit.socket

# Create directory for custom Cockpit socket configuration
echo "Setting custom port for Cockpit..."
sudo mkdir -p /etc/systemd/system/cockpit.socket.d/
sudo bash -c 'cat > /etc/systemd/system/cockpit.socket.d/listen.conf' << EOF
[Socket]
ListenStream=
ListenStream=2400
EOF

# Reload and restart Cockpit service
sudo systemctl daemon-reload
sudo systemctl restart cockpit.socket

# Configure Netplan network settings
echo "Configuring network settings with Netplan..."
sudo bash -c 'cat > /etc/netplan/00-installer-config.yaml' << EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    esp4so:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.31.24/24
      routes:
        - to: default
          via: 192.168.31.1
      nameservers:
        addresses: [8.8.8.8,8.8.4.4,192.168.31.1]
EOF

# Apply Netplan configuration
sudo netplan try

# Add 45Drives repository and update package list
echo "Adding 45Drives repository and updating..."
curl -sSL https://repo.45drives.com/setup | sudo bash
sudo apt-get update

# Install additional Cockpit modules
echo "Installing Cockpit modules..."
sudo apt install -y cockpit-file-sharing cockpit-navigator

# Create directory /ttserver and set permissions
echo "Creating /ttserver directory and setting ownership..."
sudo mkdir -p /ttserver
sudo chown -R ttserver:ttserver /ttserver

# Install Samba
echo "Installing Samba..."
sudo apt install -y samba

# Create Samba user with specific password
echo "Creating Samba user 'nfserver' with password 'PenelopeTT2901'..."
(echo "PenelopeTT2901"; echo "PenelopeTT2901") | sudo smbpasswd -a nfserver

# Configure Samba to share /nfserver
echo "Configuring Samba share..."
sudo mkdir -p /nfserver
sudo bash -c 'cat >> /etc/samba/smb.conf' << EOF

[NFServer]
  path = /nfserver
  read only = no
  inherit permissions = yes
EOF

# Restart Samba service
sudo systemctl restart smbd

echo "Setup completed successfully!"
