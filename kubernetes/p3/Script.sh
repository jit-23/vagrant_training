#!/bin/bash

set -e

GREEN="\e[32m"
END="\e[0m"



## CURL ## 

if ! command -v curl >/dev/null 2>&1; then
    echo "${GREEN}Installing curl...${END}"
    sudo apt update && sudo apt install curl -y
    echo "curl installed."
fi 

## DOCKER ##

if ! command -v docker >/dev/null 2>&1; then
    echo "${GREEN}Installing Docker...${END}"
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

if ! command -v kubectl >/dev/null 2>&1; then
    echo "${GREEN}Installing kubectl...${END}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    echo "kubectl installed."
fi

## k3d installation ##
if ! command -v k3d >/dev/null 2>&1; then
    echo "${GREEN}Installing k3d...${END}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "k3d installed."
fi

## KUBECONFIG ##

mkdir -p ~/.kube
chown -R $USER:$USER ~/.kube

if [ ! -f  "$HOME/.kube/config" ]; then
    echo "Setting up kubeconfig..."
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
fi

## K3d cluster ##

if ! k3d cluster list | grep -q "mycluster"; then
    echo "${GREEN}Creating k3d cluster...${END}"
    k3d cluster create --config K3dConfig.yaml
    echo "k3d cluster created."
fi

<<<<<<< HEAD
=======
## KUBECONFIG ##

mkdir -p ~/.kube
k3d kubeconfig merge mycluster --kubeconfig-merge-default



>>>>>>> 5e08b07510286e42dc9e49c264159317b64442c8
## argoCD install ##
if ! kubectl get namespace argocd >/dev/null 2>&1; then
    echo "${GREEN}Installing argoCD...${END}"
    kubectl create namespace argocd
    sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "argoCD installed."
fi

if ! kubectl get namespace dev >/dev/null 2>&1; then
    echo "${GREEN}Creating dev namespace...${END}"
    kubectl create namespace dev
fi



## RUN argoCD ##

until kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; do
    echo "${GREEN}Waiting for ArgoCD admin secret...${END}"
    sleep 5
done

until kubectl get pod -n argocd -l app.kubernetes.io/name=argocd-server --field-selector=status.phase=Running 2>/dev/null | grep -q Running; do
    echo "${GREEN}Waiting for ArgoCD server pod to be Running...${END}"
    sleep 5
done

PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "${GREEN}CREDENTIALS${END}"
echo "--------------------------------"
echo "${GREEN}User${END}: admin"
echo "${GREEN}Password${END}: ${PASS}"
echo "--------------------------------"
echo "Port forwarding ArgoCD server on ${GREEN}localhost:8000${END}"
#kubectl port-forward svc/argocd-server -n argocd 8000:443 
# the line below is for the argcd to run on the background, not very usefull on development
nohup kubectl port-forward svc/argocd-server -n argocd 8000:443 &

until nc -z localhost 8000 2>/dev/null; do
    sleep 1
done

## argocd configuration ##

if ! command -v argocd >/dev/null 2>&1; then
    echo "${GREEN}installing argocd CLI${END}"
    curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 /tmp/argocd /usr/local/bin/argocd
    rm /tmp/argocd
fi


## DEPLOYING APP THROUGH ARGOCD CLI ##

## LOGIN ##
argocd login localhost:8000 --insecure --username admin --password "${PASS}"
echo "${GREEN}LOGGED ON ARGOCD${END}"

## CREATING APP ##

argocd app create playground \
    --repo https://github.com/jit-23/playground.git \
    --path . \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace dev \
    --upsert

## SYNC APP ##
argocd app sync playground
argocd app set playground --sync-policy automated

## HEALTH CHECK ##
argocd app wait playground --health

## PORT FORWARD APP ##
kubectl port-forward svc/playground 8888:8888 -n dev 

until nc -z localhost 8888 2>/dev/null; do
        sleep 1
done
echo "${GREEN}App available at http://localhost:8888${END}"

# -> cmd bellow is to show the endpoints like in the subject image
#kubectl edit cm argocd-cm -n argocd
