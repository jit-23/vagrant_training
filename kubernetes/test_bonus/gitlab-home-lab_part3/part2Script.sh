#!/bin/bash


set -e

GREEN='\e[32m'
END='\e[0m'


if command -v openssl >/dev/null 2>&1; then
    echo "${GREEN}installing openssl${END}"
    sudo apt update && sudo apt install openssl
fi

mkdir -p ssl && cd ssl

#   create a file named -> "openssl.cnf"
#
#   and add the following information 
#
#```                ## openssl.cnf ##
#[req]
#distinguished_name = req_distinguished_name
#x509_extensions = v3_ca
#prompt = no
#
#[req_distinguished_name]
#countryName = MA
#stateOrProvinceName = Casablanca
#localityName = Casablanca
#organizationName = YasserElKhayati
#commonName = gitlab.yasserelkhayati.com
#
#[v3_ca]
#subjectAltName = IP:127.0.0.1,DNS:gitlab.fernando.com
#```
#
###################################################
#this cmd will create all the certs
#          |
#          |
#          V

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout gitlab.yasserelkhayati.com.key -out gitlab.yasserelkhayati.com.crt -config openssl.cnf
#-------------------------------------------------------------------------------------

# tutorial of how to do this:
#https://medium.com/@yasserelkhayati28/part-2-from-zero-to-gitlab-securing-your-gitlab-server-with-a-self-signed-ssl-certificate-8ab0ac68230a