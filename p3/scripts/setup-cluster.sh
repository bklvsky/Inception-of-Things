#!/bin/bash

# Inception-of-Things Part 3 - Cluster Setup Script
# This script creates K3D cluster and installs ArgoCD

set -e

echo "Setting up IoT Part 3 Cluster"
echo "=============================="

# Create K3D cluster
echo "Creating K3D cluster..."
if ! k3d cluster list | grep -q iot-cluster; then
    k3d cluster create iot-cluster \
        --port "8888:8888@loadbalancer" \
        --port "30080:80@loadbalancer" \
        --port "30443:443@loadbalancer" \
        --api-port 6443
    echo "K3D cluster 'iot-cluster' created successfully"
else
    echo "K3D cluster 'iot-cluster' already exists"
fi

# Configure kubectl to use the cluster
echo "Configuring kubectl..."
k3d kubeconfig merge iot-cluster --kubeconfig-switch-context

# Verify cluster is running
echo "Verifying cluster status..."
kubectl cluster-info
kubectl get nodes

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD admin password
echo "Getting ArgoCD admin password..."
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-password.txt
echo ""
echo "ArgoCD admin password saved to argocd-password.txt"

# Create dev namespace
echo "Creating dev namespace..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

# Create ArgoCD Application for automatic deployment
echo "Setting up ArgoCD Application from GitHub..."
kubectl apply -f https://raw.githubusercontent.com/Slava-Nya/IoT-42test-hlorrine/main/argocd/application.yaml

# Wait for application to be synced and deployed
echo "Waiting for application deployment..."
kubectl wait --for=condition=Synced --timeout=300s application/wil-playground -n argocd || echo "Sync timeout, but continuing..."
kubectl get pods -n dev

# Port forward ArgoCD (run in background)
echo "Setting up ArgoCD port forwarding..."
# Kill any existing port-forward processes
pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null || true
nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0 > /dev/null 2>&1 &

echo ""
echo "Cluster setup completed successfully!"
echo "===================================="
echo "Cluster Info:"
echo "  • K3D Cluster: iot-cluster"
echo "  • ArgoCD UI: https://localhost:8080"
echo "  • Username: admin"
echo "  • Password: $(cat argocd-password.txt)"
echo ""
echo "To configure remote access run locally:"
echo "   ssh -L 18888:localhost:8888 -L 18080:localhost:8080 $(whoami)@$(hostname -I | awk '{print $1}')"
echo "  Then open: http://localhost:18888 (app) & https://localhost:18080 (ArgoCD)"
echo ""
echo "To destroy cluster: Run './scripts/cleanup-cluster.sh'"
