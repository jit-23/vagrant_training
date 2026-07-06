#! /bin/bash

sudo kubectl apply -f namespace.yaml
sudo kubectl apply -f postgres/postgres.yaml

sudo kubectl apply -f redis/redis.yaml

sudo kubectl apply -f gitlab/gitlab.yaml

sudo kubectl port-forward -n microservice svc/gitlab 8082:80
