#!/bin/bash

	echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
	sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list
	sed -i '/security.debian.org/d' /etc/apt/sources.list
	apt-get update && echo "whoami: $(whoami)"
	DEBIAN_FRONTEND=noninteractive apt-get install curl -y
	echo "done with curl installation"
	curl -4 -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=1234567890 INSTALL_K3S_EXEC="--node-name k3s-worker" sh -

#	NODE_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
#	sudo k3s agent --server https://192.168.56.110:6443 --token ${NODE_TOKEN}