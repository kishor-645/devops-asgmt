#!/bin/bash

# Local ngrok Testing Script for Kind Cluster
# This script tests ngrok tunnel setup with your local k8s cluster

set -e

echo "======================================================================"
echo "           LOCAL NGROK TESTING SCRIPT FOR KIND CLUSTER"
echo "======================================================================"
echo ""

# Step 1: Check if cluster exists
echo "Step 1: Checking Kind cluster..."
kubectl cluster-info --context kind-k8s 2>/dev/null || {
  echo "❌ Cluster 'kind-k8s' not found!"
  echo "Available clusters:"
  kubectl config get-contexts
  exit 1
}
echo "✅ Cluster 'kind-k8s' is accessible"
echo ""

# Step 2: Check if the dev namespace has the app
echo "Step 2: Checking if deployment exists..."
NAMESPACE="dev"
if kubectl get namespace $NAMESPACE 2>/dev/null; then
  echo "✅ Namespace '$NAMESPACE' exists"
  kubectl get pods -n $NAMESPACE
else
  echo "❌ Namespace '$NAMESPACE' not found"
  echo "Creating namespace..."
  kubectl create namespace $NAMESPACE
fi
echo ""

# Step 3: Get service details
echo "Step 3: Service Details..."
SERVICE_IP=$(kubectl get svc spring-app-service -n $NAMESPACE -o jsonpath='{.status.clusterIP}' 2>/dev/null || echo "")
SERVICE_PORT=$(kubectl get svc spring-app-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "")

if [ -z "$SERVICE_IP" ]; then
  echo "❌ Service not found"
  echo "Available services:"
  kubectl get svc -n $NAMESPACE
  exit 1
fi

echo "✅ Service found:"
echo "   Cluster IP: $SERVICE_IP"
echo "   Port: $SERVICE_PORT"
echo ""

# Step 4: Test direct cluster access
echo "Step 4: Testing direct cluster access via port-forward..."
echo "Starting port-forward: localhost:8080 -> $SERVICE_IP:$SERVICE_PORT"

# Kill any existing port-forward processes
pkill -f "kubectl port-forward" || true
sleep 2

# Start new port-forward
kubectl port-forward -n $NAMESPACE svc/spring-app-service 8080:$SERVICE_PORT > /tmp/portforward.log 2>&1 &
PF_PID=$!
echo "Port-forward started (PID: $PF_PID)"
sleep 3

# Test the connection
echo "Testing connection to localhost:8080..."
if curl -s http://localhost:8080/api/messages > /dev/null; then
  echo "✅ Direct access works!"
else
  echo "❌ Direct access failed"
  echo "Port-forward logs:"
  cat /tmp/portforward.log
fi
echo ""

# Step 5: Check ngrok installation
echo "Step 5: Checking ngrok installation..."
if command -v ngrok &> /dev/null; then
  echo "✅ ngrok is already installed"
  ngrok version
else
  echo "📥 Installing ngrok..."
  
  # Check OS
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Windows detected. Download ngrok from: https://ngrok.com/download"
    echo "Extract and add to PATH, or run: ngrok.exe http 8080"
    exit 0
  elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
    unzip -q ngrok-v3-stable-linux-amd64.zip
    chmod +x ngrok
    echo "✅ ngrok installed"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install ngrok/ngrok/ngrok || wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip && unzip -q ngrok-v3-stable-darwin-amd64.zip
    echo "✅ ngrok installed"
  fi
fi
echo ""

# Step 6: Start ngrok tunnel
echo "Step 6: Starting ngrok tunnel..."
echo "⚠️  IMPORTANT: This script will start ngrok and hold open for testing"
echo ""
echo "ngrok will expose your local app at a public URL!"
echo "You can stop it anytime by pressing Ctrl+C"
echo ""

# Kill any existing ngrok processes
pkill -f ngrok || true
sleep 2

# Start ngrok with API logging
echo "Starting: ngrok http 8080 --log=stdout"
./ngrok http 8080 --log=stdout 2>&1 | tee /tmp/ngrok.log &
NGROK_PID=$!
echo "ngrok started (PID: $NGROK_PID)"
echo ""

# Wait for ngrok to initialize
echo "Waiting for ngrok to initialize..."
sleep 5

# Get ngrok URL from API
echo ""
echo "Step 7: Retrieving ngrok URL..."
for attempt in {1..10}; do
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*' | head -1 | cut -d'"' -f4 || echo "")
  
  if [ ! -z "$NGROK_URL" ]; then
    echo "✅ ngrok tunnel established!"
    break
  fi
  
  if [ $attempt -lt 10 ]; then
    echo "   Attempt $attempt/10: Waiting for ngrok API..."
    sleep 2
  fi
done

if [ -z "$NGROK_URL" ]; then
  echo "❌ Failed to get ngrok URL from API"
  echo "Trying alternative method..."
  
  # Try to extract from logs
  sleep 3
  NGROK_URL=$(grep -o "started tunnel session.*[a-z0-9]*\.ngrok\.io" /tmp/ngrok.log 2>/dev/null | tail -1 | awk '{print $NF}' || echo "")
  
  if [ ! -z "$NGROK_URL" ]; then
    echo "✅ Found URL in logs: $NGROK_URL"
  else
    echo "⚠️  Could not extract ngrok URL"
    echo "Check ngrok logs:"
    tail -20 /tmp/ngrok.log
  fi
fi

echo ""
echo "======================================================================"
echo "                    🌐 TESTING WINDOW OPEN 🌐"
echo "======================================================================"
echo ""
echo "✅ Public ngrok URL: $NGROK_URL"
echo ""
echo "Test endpoints:"
echo "  • GET  messages: curl $NGROK_URL/api/messages"
echo "  • POST message:  curl -X POST -H 'Content-Type: text/plain' -d 'test' $NGROK_URL/api/messages"
echo "  • Browser:       $NGROK_URL/api/messages"
echo ""
echo "Local direct access:"
echo "  • GET  messages: curl http://localhost:8080/api/messages"
echo "  • Port-forward:  kubectl port-forward -n $NAMESPACE svc/spring-app-service 8080:$SERVICE_PORT"
echo ""
echo "======================================================================"
echo ""
echo "Cluster status:"
kubectl get all -n $NAMESPACE
echo ""
echo "Holding for 5 minutes (300 seconds)..."
echo "Press Ctrl+C to stop ngrok and port-forward"
echo ""

# Hold for 5 minutes
sleep 300

# Cleanup
echo ""
echo "======================================================================"
echo "              Cleaning up port-forward and ngrok..."
echo "======================================================================"
kill $PF_PID 2>/dev/null || true
kill $NGROK_PID 2>/dev/null || true
sleep 2

echo "✅ Cleanup complete"
echo ""
