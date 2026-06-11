#!/bin/bash

set -e

docker compose up -d
echo "127.0.0.1  gitlab.fernando.com" | sudo tee -a /etc/hosts
