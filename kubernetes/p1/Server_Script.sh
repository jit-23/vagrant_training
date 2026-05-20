#!/bin/bash
	
	echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
	sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list
	sed -i '/security.debian.org/d' /etc/apt/sources.list
	apt-get update && echo "whoami: $(whoami)"
	DEBIAN_FRONTEND=noninteractive apt-get install curl -y
	echo "done with curl installation"
	curl -4 -sfL https://get.k3s.io | K3S_TOKEN=1234567890 INSTALL_K3S_EXEC="--tls-san 192.168.56.110" sh -

# Kubeconfig is written to /etc/rancher/k3s/k3s.yaml
until sudo k3s kubectl get node 2>/dev/null | grep -q "Ready"; do
 	sleep 5
done 


echo "Node token: $(cat /var/lib/rancher/k3s/server/node-token)"



# On a different node run the below command. 
# NODE_TOKEN comes from /var/lib/rancher/k3s/server/node-token on your server