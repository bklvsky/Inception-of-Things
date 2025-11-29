#!/bin/bash

# Inception-of-Things Part 3 - Environment Installation Script
# This script installs Docker, kubectl, and K3D

set -e

echo "Installing IoT Part 3 Environment"
echo "=================================="

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker (required for K3D)
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install kubectl
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "kubectl installed successfully"
else
    echo "kubectl already installed"
fi

# Install K3D
echo "Installing K3D..."
if ! command -v k3d &> /dev/null; then
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "K3D installed successfully"
else
    echo "K3D already installed"
fi

echo ""
echo "Environment installation completed!"
echo "=================================="
echo "Installed tools:"
echo "  • Docker: $(docker --version 2>/dev/null || echo 'Failed')"
echo "  • kubectl: $(kubectl version --client 2>/dev/null | head -n1 | awk '{print $3}' || echo 'Failed')"
echo "  • K3D: $(k3d version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'Failed')"
echo ""
echo "Next step: Run './scripts/setup-cluster.sh' to create the cluster"
echo ""
echo "Note: You may need to logout and login again for Docker group permissions to take effect"
