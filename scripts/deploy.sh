#!/usr/bin/bash
source .env
podman pod create --name Vertex -p 5432:5432/TCP -p 50051:50051/TCP -p 3000:3000/TCP 
podman build -f Containerfile --rm -t localhost/vertex-db:v0.1 --no-cache
podman run -d --rm --pod Vertex --name vertex-db -e POSTGRES_PASSWORD=postgres localhost/vertex-db:v0.1
