# Part 3: K3D and ArgoCD Manual Testing Guide

Step-by-step guide for testing K3D + ArgoCD + GitOps setup

---

## Prerequisites

- Virtual machine with Linux (Ubuntu 24.04 recommended)
- Internet connection
- SSH access to VM (if working remotely)

---

## Step 1: Environment Setup

### 1.1 Run Installation Script

```bash
cd /path/to/p3
./install.sh
```

**What it does:**
- Installs Docker, kubectl, K3D
- Creates K3D cluster with 3 nodes (1 control-plane + 2 agents)
- Installs ArgoCD in `argocd` namespace
- Creates `dev` namespace for application
- Sets up port forwarding for ArgoCD UI

**Expected output:**
```
Installation completed successfully!
Cluster Info:
  • K3D Cluster: iot-cluster
  • ArgoCD UI: https://localhost:8081
  • Username: admin
  • Password: <password>
```

### 1.2 Verify Docker Access

```bash
docker ps
# If permission denied:
newgrp docker
```

---

## Step 2: Infrastructure Verification

### 2.1 Check K3D Cluster

```bash
k3d cluster list
kubectl get nodes
```

**Expected:**
```
NAME          SERVERS   AGENTS   LOADBALANCER
iot-cluster   1/1       2/2      true
```

### 2.2 Check Namespaces

```bash
kubectl get namespaces
```

**Expected:** `argocd` and `dev` namespaces exist

---

## Step 3: ArgoCD Setup

### 3.1 Verify ArgoCD Pods

```bash
kubectl get pods -n argocd
```

**All pods should be Running**

### 3.2 Get ArgoCD Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### 3.3 Access ArgoCD UI

**Option A: Direct access (if VM has GUI)**
```
https://localhost:8081
```

**Option B: SSH tunnel (if working remotely)**
```bash
# On local machine:
ssh -L 9080:localhost:8081 -L 9888:localhost:8888 user@vm-ip

# Then open: https://localhost:9080
```

**Login:** admin / `<password>`

---

## Step 4: Configure ArgoCD Application

**Note:** Download the GitHub repository to get the required YAML files:
```bash
# Clone the GitHub repository into p3/confs/app folder
git clone https://github.com/Slava-Nya/IoT-42test-hlorrine.git app
cd app

# Required files structure:
├── deployment.yaml    # Kubernetes Deployment
├── service.yaml       # Kubernetes Service
└── ingress.yaml       # Kubernetes Ingress
```

---

## Step 5: Deploy Application via ArgoCD

### 5.1 Apply ArgoCD Application

```bash
kubectl apply -f confs/argocd/application.yaml
```

### 5.2 Verify Application Status

```bash
kubectl get applications -n argocd
```

**Expected:** `Synced` and `Healthy`

### 5.3 Check Application Resources

```bash
kubectl get all -n dev
```

**Expected:** Pod, Service, Deployment running

---

## Step 6: Test Application

### 6.1 Port Forward to Application

```bash
kubectl port-forward -n dev svc/iot-app-service 8888:8888 &
```

### 6.2 Test Application

```bash
curl http://localhost:8888/
```

**Expected output (v1):**
```json
{"status":"ok", "message": "v1"}
```

**Via SSH tunnel (local machine):**
```bash
curl http://localhost:9888/
```

---

## Step 7: GitOps Demo - Version Switch

### 7.1 Change Version in GitHub

```bash
# Edit in the cloned GitHub repository
cd app
nano deployment.yaml

# Change:
image: wil42/playground:v1  →  wil42/playground:v2
value: "v1"  →  value: "v2"

git add deployment.yaml
git commit -m "Update to v2"
git push
```

### 7.2 Force ArgoCD Sync

```bash
# Install ArgoCD CLI if needed
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd-linux-amd64

# Login and sync
echo "y" | ./argocd-linux-amd64 login localhost:8081 --username admin --password <password> --insecure
./argocd-linux-amd64 app sync iot-app
```

### 7.3 Verify Version Change

```bash
curl http://localhost:8888/
```

**Expected output (v2):**
```json
{"status":"ok", "message": "v2"}
```

### 7.4 Check Pod Restart

```bash
kubectl get pods -n dev -w
```

**Should see:** Old pod terminating, new pod starting

---

## Step 8: Rollback Demo

### 8.1 Rollback via GitHub

```bash
# Edit in the cloned GitHub repository
cd app
nano deployment.yaml
# Change: v2 → v1

git add deployment.yaml
git commit -m "Rollback to v1"
git push
```

### 8.2 Sync and Verify

```bash
./argocd-linux-amd64 app sync iot-app
curl http://localhost:8888/
```

**Should return v1 response**

---

## Step 9: Additional Checks

### 9.1 ArgoCD History

```bash
./argocd-linux-amd64 app history iot-app
```

### 9.2 Test Ingress (Optional)

```bash
# Start Traefik port-forward
kubectl port-forward -n kube-system svc/traefik 8082:80 &

# Test ingress
curl -H "Host: playground.com" http://localhost:8082/
```


## Step 10: Cleanup

### 10.1 Remove Application from ArgoCD

```bash
# Delete ArgoCD Application (this will also remove resources from dev namespace)
kubectl delete application iot-app -n argocd
```

### 10.2 Stop Port Forwarding

```bash
# Stop all port-forward processes
pkill -f "port-forward"
```

### 10.3 Delete K3D Cluster

```bash
# Delete the entire K3D cluster
k3d cluster delete iot-cluster
```

---

## Quick Commands Reference

### K3D
```bash
k3d cluster list                    # List clusters
k3d cluster create <name>          # Create cluster
k3d cluster delete <name>          # Delete cluster
```

### kubectl
```bash
kubectl get pods -n <namespace>    # List pods
kubectl get all -n <namespace>     # All resources
kubectl logs -f <pod> -n <ns>      # Pod logs
kubectl port-forward svc/<svc> 8888:8888  # Port forward
```

### ArgoCD CLI
```bash
argocd app list                    # List applications
argocd app get <name>              # App details
argocd app sync <name>             # Sync application
argocd app history <name>          # Sync history
```

---

## Troubleshooting

### ArgoCD UI 404
```bash
# Check port-forward
ps aux | grep port-forward

# Restart if needed
kubectl port-forward svc/argocd-server -n argocd 8081:443 --address=127.0.0.1 &
```

### Application OutOfSync
```bash
# Check repository URL
kubectl get application iot-app -n argocd -o yaml | grep repoURL

# Force sync
./argocd-linux-amd64 app sync iot-app
```

### Pod ImagePullBackOff
```bash
# Check image availability
docker pull wil42/playground:v1
```
