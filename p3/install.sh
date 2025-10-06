#!/bin/bash

# Inception-of-Things Part 3 - K3D and ArgoCD Installation Script
# This script installs all necessary packages and tools for Part 3

set -e

echo "Starting Inception-of-Things Part 3 Installation"
echo "=================================================="

# Update system
echo " Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker (required for K3D)
echo " Installing Docker..."
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

# Create K3D cluster
echo "Creating K3D cluster..."
if ! k3d cluster list | grep -q iot-cluster; then
    k3d cluster create iot-cluster \
        --port "8080:80@loadbalancer" \
        --port "8443:443@loadbalancer" \
        --api-port 6443 \
        --agents 2
    echo " K3D cluster 'iot-cluster' created successfully"
else
    echo " K3D cluster 'iot-cluster' already exists"
fi

# Configure kubectl to use the cluster
echo " Configuring kubectl..."
k3d kubeconfig merge iot-cluster --kubeconfig-switch-context

# Verify cluster is running
echo " Verifying cluster status..."
kubectl cluster-info
kubectl get nodes

# Install ArgoCD
echo " Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo " Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD admin password
echo " Getting ArgoCD admin password..."
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-password.txt
echo ""
echo " ArgoCD admin password saved to argocd-password.txt"

# Create dev namespace
echo " Creating dev namespace..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

# Port forward ArgoCD (run in background)
echo " Setting up ArgoCD port forwarding..."
nohup kubectl port-forward svc/argocd-server -n argocd 8081:443 --address=127.0.0.1 > /dev/null 2>&1 &

echo ""
echo " Installation completed successfully!"
echo "======================================"
echo " Cluster Info:"
echo "  • K3D Cluster: iot-cluster"
echo "  • ArgoCD UI: https://localhost:8081"
echo "  • Username: admin"
echo "  • Password: $(cat argocd-password.txt)"
echo ""
echo " Next Steps:"
echo "  1. Create Github repository"
echo "  2. Push application configurations"
echo "  3. Configure ArgoCD application"
echo ""
echo "  Note: You may need to logout and login again for Docker group permissions to take effect"
