#!/bin/bash

# Docker Relocation Script for Cloudlab
# Relocates Docker data directory from /var/lib/docker to /mnt/extra/docker
# This is necessary on Cloudlab where / is typically provisioned with only 16 GB

set -e  # Exit on any error

echo "=== Docker Relocation Script for Cloudlab ==="
echo "This script will relocate Docker data directory to /mnt/extra/docker"
echo

# Check if /mnt/extra exists
if [ ! -d "/mnt/extra" ]; then
    echo "Error: /mnt/extra directory does not exist."
    echo "Please ensure the extra disk is mounted at /mnt/extra first."
    echo "You can use c6420_disk_setup.sh to set up the disk."
    exit 1
fi

# Step 1: Stop Docker service
echo "Step 1: Stopping Docker service..."
sudo systemctl stop docker
echo "Docker service stopped."
echo

# Step 2: Create new Docker data directory
echo "Step 2: Creating new Docker data directory at /mnt/extra/docker..."
sudo mkdir -p /mnt/extra/docker
echo "Directory created."
echo

# Step 3: Configure Docker to use new data directory
echo "Step 3: Configuring Docker to use new data directory..."

# Create /etc/docker directory if it doesn't exist
sudo mkdir -p /etc/docker

# Create or update daemon.json
echo "Creating/updating /etc/docker/daemon.json..."
cat << 'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
    "data-root": "/mnt/extra/docker"
}
EOF
echo "Docker daemon configuration updated."
echo

# Step 4: Add current user to docker group
echo "Step 4: Adding current user ($USER) to docker group..."
sudo usermod -aG docker $USER
echo "User added to docker group."
echo

# Step 5: Start Docker service
echo "Step 5: Starting Docker service..."
sudo systemctl start docker
echo "Docker service started."
echo

# Final instructions
echo "=== IMPORTANT: Manual Steps Required ==="
echo "1. You must LOGOUT and LOGIN again for the docker group changes to take effect."
echo "2. After logging back in, verify the setup by running:"
echo "   docker info | grep 'Docker Root Dir'"
echo "3. You should see: Docker Root Dir: /mnt/extra/docker"

echo "Docker relocation script completed successfully!" 