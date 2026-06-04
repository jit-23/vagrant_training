#!/bin/bash
# 1 - install/update  curl
# install k3s
# install kubectl (k3s)
# apply the yaml files

apt-get update -y
apt-get install curl -y

curl -4 -sfL https://get.k3s.io | K3S_TOKEN=1234567890 INSTALL_K3S_EXEC="--tls-san 192.168.56.110" INSTALL_K3S_SKIP_SELINUX_RPM=true sh -


until kubectl get node 2>/dev/null | grep -q "Ready"; do
 	sleep 5
done

sh /tmp/deployment.sh

echo "127.0.0.1 app1.com" | sudo tee -a /etc/hosts
echo "127.0.0.1 app2.com" | sudo tee -a /etc/hosts
echo "127.0.0.1 app3.com" | sudo tee -a /etc/hosts