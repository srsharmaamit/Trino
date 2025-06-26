#!/bin/bash
set -e

# Docker image configuration
IMAGE_NAME="trino"
IMAGE_TAG="446"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building Trino Docker image: ${FULL_IMAGE_NAME}"

# Build the Docker image
docker build -t ${FULL_IMAGE_NAME} .

echo "Docker image built successfully: ${FULL_IMAGE_NAME}"

# Optional: Tag with latest
docker tag ${FULL_IMAGE_NAME} ${IMAGE_NAME}:latest

echo "Available images:"
docker images | grep ${IMAGE_NAME}

echo ""
echo "To run the image:"
echo "docker run -d -p 8080:8080 --name trino-coordinator ${FULL_IMAGE_NAME}"
echo ""
echo "To push to registry:"
echo "docker tag ${FULL_IMAGE_NAME} your-registry.com/${FULL_IMAGE_NAME}"
echo "docker push your-registry.com/${FULL_IMAGE_NAME}"