#!/bin/bash

## Docker installation ##
# add it later  

## kubectl installation ##

#curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#chmod +x kubectl
#mv kubectl /usr/local/bin/kubectl


mkdir -p ~/.kube
chown -R $USER:$USER ~/.kube  
 sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
#kubectl version --client
k3d cluster create --config K3dConfig.yaml
echo "127.0.0.1 app.com" | sudo tee -a /etc/hosts 


## k3d installation ##

#apt update && apt upgrade
#apt install curl
#curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

## argoCD install ##
echo "kubectl create namespace argocd" 

kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## k3d configuration ##



## sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo
