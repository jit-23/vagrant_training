#!/bin/bash

set -e

GREEN="\e[32m"
END="\e[0m"

# script to install terminator and etc...

sudo apt update

# 2. Let apt install the exact version explicitly alongside terminator
# otherwise it will not be able to install terminator because of the version conflict with python3-gi and python3-gi-cairo
sudo apt install terminator python3-gi=3.56.1-2 python3-gi-cairo

# 3. If that still conflicts, fix any half-broken state
sudo apt --fix-broken install

echo -e "${GREEN}Terminator and dependencies installed successfully.${END}"


## helm ##

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

## glab ##

# Add the WakeMeOps repository
curl -sSL "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | sudo bash

# Install glab
sudo apt install glab

## install gitlab runners ##

helm repo add gitlab https://charts.gitlab.io
helm repo update

kubectl create namespace gitlab

#Verify and checkout to new namespace.
kubectl describe namespace gitlab
Name:         gitlab
Labels:       kubernetes.io/metadata.name=gitlab
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.

# set current context to gitlab namespace
$ kubectl config set-context --current --namespace=gitlab


# check the version of gitlab-runner helm chart and pick one
helm search repo -l gitlab/gitlab-runner

# install the runner (I manually pick the latest version, but dropping it will install latest as well)
helm install gitlab-runner --namespace gitlab --version 0.89.1 -f gitlab-runner-values.yaml gitlab/gitlab-runner

## install gitlab runner ?  ##


sudo curl -L --output /usr/local/bin/gitlab-runner \
  "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
sudo chmod +x /usr/local/bin/gitlab-runner

# Create a dedicated user and install the service
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start