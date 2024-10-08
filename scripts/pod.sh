#!/usr/bin/bash
podman pod create --name Vertex -p 5432:5432/TCP -p 50051:50051/TCP -p 4000:4000/TCP -p 3000:3000/TCP 
podman build -f Containerfile --rm -t localhost/vertex-db:v0.1 

source .env
podman run -dit --rm \
    --pod Vertex \
    --name vertex-db \
    -e POSTGRES_PASSWORD=${DB_PASS} \
    localhost/vertex-db:v0.1
