#!/bin/bash

set -e

## CURL ## 

if ! command -v curl &>/dev/null; then 
    echo "Installing curl..."
    sudo apt update && sudo apt install curl -y
    echo "curl installed."
fi 

## DOCKER ##

if ! command -v docker &>/dev/null; then
    echo "Installing Docker..."
    sudo apt update
    sudo apt install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
    Types: deb
    URIs: https://download.docker.com/linux/ubuntu
    Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
    Components: stable
    Architectures: $(dpkg --print-architecture)
    Signed-By: /etc/apt/keyrings/docker.asc
EOF
    sudo apt update 
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    # Add Docker's official GPG key:
    echo "Docker installed."
fi


## KUBECTL ##

if ! command -v kubectl &>/dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    echo "kubectl installed."
fi

## k3d installation ##
if ! command -v k3d &>/dev/null; then
    echo "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "k3d installed."
fi

## K3d cluster ##

if ! k3d cluster list | grep -q "mycluster"; then
    echo "Creating k3d cluster..."
    k3d cluster create --config K3dConfig.yaml
    echo "k3d cluster created."
fi

## KUBECONFIG ##

mkdir -p ~/.kube
k3d kubeconfig merge mycluster --kubeconfig-merge-default

## argoCD install ##
if ! kubectl get namespace argocd &>/dev/null; then
    echo "Installing argoCD..."
    kubectl create namespace argocd
    sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "argoCD installed."
fi

if ! kubectl get namespace dev &>/dev/null; then
    echo "Creating dev namespace..."
    kubectl create namespace dev
fi

## RUN argoCD ##

echo "User: admin"
echo "Password: " 
sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo


echo "Port forwarding ArgoCD server to localhost:8000"
kubectl port-forward svc/argocd-server -n argocd 8000:443

