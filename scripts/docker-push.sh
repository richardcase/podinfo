#!/bin/bash

if [ -z "$DOCKER_USER" ]; then
    echo "PR build, skipping Docker Hub push";
else
    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin;
    make docker-push;
fi
