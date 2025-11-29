#!/bin/bash

# Inception-of-Things Part 3 - Cleanup Script
# This script removes K3D cluster and cleans up configurations

set -e

echo "Cleaning up IoT Part 3 Cluster"
echo "==============================="

# Stop ArgoCD port-forward processes
echo "Stopping ArgoCD port-forward processes..."
pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null && echo "Port-forward processes stopped" || echo "No port-forward processes found"

# Delete K3D cluster
echo "Deleting K3D cluster..."
if k3d cluster list | grep -q iot-cluster; then
    k3d cluster delete iot-cluster
    echo "K3D cluster 'iot-cluster' deleted successfully"
else
    echo "K3D cluster 'iot-cluster' not found"
fi

# Clean up kubectl context
echo "Cleaning up kubectl context..."
kubectl config delete-context k3d-iot-cluster 2>/dev/null && echo "kubectl context removed" || echo "kubectl context not found"
kubectl config delete-cluster k3d-iot-cluster 2>/dev/null && echo "kubectl cluster removed" || echo "kubectl cluster not found"
kubectl config unset users.admin@k3d-iot-cluster 2>/dev/null && echo "kubectl user removed" || echo "kubectl user not found"

# Remove generated files
echo "Cleaning up generated files..."
if [ -f "argocd-password.txt" ]; then
    rm argocd-password.txt
    echo "ArgoCD password file removed"
fi

# List remaining K3D clusters
echo ""
echo "Remaining K3D clusters:"
k3d cluster list || echo "No clusters found"

# Show current kubectl context
echo ""
echo "Current kubectl context:"
kubectl config current-context 2>/dev/null || echo "No active context"

echo ""
echo "Cleanup completed successfully!"
echo "==============================="
