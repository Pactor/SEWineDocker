#!/bin/bash
set -e

# Name or partial name of your Torch container
NAME="sewine"

echo "🔍 Searching for containers..."
CONTAINER_ID=$(docker ps -a --filter "name=$NAME" --format "{{.ID}}")

if [ -n "$CONTAINER_ID" ]; then
    echo "🧹 Stopping and removing container(s)..."
    docker stop $CONTAINER_ID || true
    docker rm -f $CONTAINER_ID || true
else
    echo "⚠️  No container with name containing '$NAME' found."
fi

echo "🧹 Removing images..."
docker images | grep "$NAME" | awk '{print $3}' | xargs -r docker rmi -f

echo "🧹 Removing unused volumes and networks..."
docker volume prune -f
docker network prune -f

echo "✅ Container and related resources removed."
