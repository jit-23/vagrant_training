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