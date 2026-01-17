#!/bin/bash

# DevOps Local Setup Script
# Builds and deploys full stack to Kind cluster with port-forward

set -e

# Configuration
APP_NAME="mycodev2-app"
DOCKER_TAG="latest"
CLUSTER_NAME="kind"
NAMESPACE="dev"
HELM_RELEASE="my-stack"
LOCAL_PORT="8080"

echo "Starting local DevOps setup..."
echo ""

# Build Docker image
echo "Building Docker image..."
docker build -t $APP_NAME:$DOCKER_TAG -f docker/Dockerfile .
echo "✓ Docker image built"
echo ""

# Create Kind cluster
echo "Creating Kind cluster..."
kind create cluster --name $CLUSTER_NAME
echo "✓ Kind cluster created"
echo ""

# Load image into Kind
echo "Loading image into Kind..."
kind load docker-image $APP_NAME:$DOCKER_TAG --name $CLUSTER_NAME
echo "✓ Image loaded"
echo ""

# Create namespace
echo "Creating namespace..."
kubectl create namespace $NAMESPACE
echo "✓ Namespace created"
echo ""

# Deploy with Helm
echo "Deploying with Helm..."
helm install $HELM_RELEASE ./helm-chart -n $NAMESPACE --create-namespace
echo "✓ Helm deployment completed"
echo ""

# Wait for pods
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=spring-app -n $NAMESPACE --timeout=300s
echo "✓ All pods ready"
echo ""

# Test endpoints
echo "Testing endpoints..."
sleep 2

echo "GET /api/messages:"
curl -s http://localhost:$LOCAL_PORT/api/messages
echo ""
echo ""

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "POST /api/messages:"
curl -s -X POST -H "Content-Type: text/plain" \
  -d "Test message: $TIMESTAMP" \
  http://localhost:$LOCAL_PORT/api/messages
echo ""
echo ""

sleep 3

echo "GET /api/messages (verify):"
curl -s http://localhost:$LOCAL_PORT/api/messages
echo ""
echo ""

echo "Setup complete!"
echo "Application running at: http://localhost:$LOCAL_PORT/api/messages"
echo ""

# Setup port-forward
echo "Starting port-forward..."
kubectl port-forward -n $NAMESPACE svc/spring-app-service $LOCAL_PORT:8080
echo ""
echo "To cleanup: kind delete cluster --name $CLUSTER_NAME"


