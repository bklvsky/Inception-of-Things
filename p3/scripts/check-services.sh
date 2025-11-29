#!/bin/bash

# Inception-of-Things Part 3 - Services Check Script
# This script verifies all required services are running

echo "IoT Part 3 - Services Verification"
echo "=================================="
echo ""

# Check K3D cluster
echo "K3D Cluster Status:"
echo "----------------------"
k3d cluster list
echo ""

echo "Cluster Nodes:"
echo "------------------"
kubectl get nodes -o wide
echo ""

# Check ArgoCD services
echo "ArgoCD Services:"
echo "-------------------"
echo "ArgoCD Pods:"
kubectl get pods -n argocd
echo ""
echo "ArgoCD Services:"
kubectl get services -n argocd
echo ""
echo "ArgoCD Applications:"
kubectl get applications -n argocd -o wide
echo ""

# Check wil-playground application
echo "pplication (wil-playground):"
echo "--------------------------------"
echo "All resources in dev namespace:"
kubectl get all -n dev
echo ""
echo "Network resources:"
kubectl get ingress,endpoints,endpointslices -n dev
echo ""

# Check Traefik (Load Balancer)
echo "Traefik Load Balancer:"
echo "-------------------------"
kubectl get pods,services -n kube-system | grep traefik
echo ""

# Test application connectivity
echo "Application Connectivity Test:"
echo "---------------------------------"
echo "Testing wil-playground application..."
if curl -f http://localhost:8888/ > /dev/null 2>&1; then
    echo "wil-playground application is accessible"
    echo "Response: $(curl -s http://localhost:8888/)"
else
    echo "wil-playground application is not accessible"
fi
echo ""

# Test ArgoCD UI connectivity  
echo "Testing ArgoCD UI..."
if curl -k -f https://localhost:8080/api/version > /dev/null 2>&1; then
    echo "ArgoCD UI is accessible"
    echo "Version: $(curl -k -s https://localhost:8080/api/version)"
else
    echo "ArgoCD UI is not accessible"
fi
echo ""

# Summary
echo "SUMMARY:"
echo "==========="
echo "• K3D Cluster: $(k3d cluster list | grep iot-cluster | awk '{print $2}')"
echo "• ArgoCD Status: $(kubectl get applications -n argocd --no-headers | wc -l) application(s)"
echo "• App Pods: $(kubectl get pods -n dev --no-headers | wc -l) pod(s)"
echo "• Services: $(kubectl get services -n dev --no-headers | wc -l) service(s)"
echo ""
echo "All services verification completed!"
echo ""
echo "For remote access use:"
echo "ssh -L 18888:localhost:8888 -L 18080:localhost:8080 $(whoami)@$(hostname -I | awk '{print $1}')"
