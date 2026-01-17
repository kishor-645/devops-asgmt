#!/bin/bash

# Simple ngrok Testing Script
# This tests ngrok with a simple Docker container before testing Kubernetes

set -e

echo "======================================================================"
echo "           SIMPLE NGROK TESTING - Using Docker Container"
echo "======================================================================"
echo ""

# Step 1: Start a simple HTTP server in Docker
echo "Step 1: Starting simple HTTP server in Docker..."
CONTAINER_NAME="test-server-$$"

docker run -d \
  --name $CONTAINER_NAME \
  -p 8888:8080 \
  kennethreitz/httpbin

echo "✅ Docker container started: $CONTAINER_NAME"
sleep 2

# Test direct access
echo ""
echo "Step 2: Testing direct access to container..."
if curl -s http://localhost:8888/get > /dev/null; then
  echo "✅ Direct access works: http://localhost:8888"
else
  echo "❌ Direct access failed"
  docker stop $CONTAINER_NAME
  exit 1
fi
echo ""

# Step 3: Install ngrok if not present
echo "Step 3: Checking ngrok..."
if ! command -v ngrok &> /dev/null; then
  echo "Installing ngrok..."
  
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    echo "Windows detected!"
    echo "Download ngrok from: https://ngrok.com/download"
    echo "Extract and add to PATH"
    echo ""
    echo "Or use Chocolatey: choco install ngrok"
    echo "Or use Scoop: scoop install ngrok"
    docker stop $CONTAINER_NAME
    exit 1
  else
    wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip 2>/dev/null || {
      echo "Failed to download ngrok"
      docker stop $CONTAINER_NAME
      exit 1
    }
    unzip -q ngrok-v3-stable-linux-amd64.zip
    chmod +x ngrok
    echo "✅ ngrok installed"
  fi
fi

echo "ngrok version:"
./ngrok version
echo ""

# Step 4: Start ngrok tunnel
echo "Step 4: Starting ngrok tunnel to localhost:8888..."
echo ""

# Kill any existing ngrok
pkill -f ngrok || true
sleep 2

# Start ngrok
./ngrok http 8888 --log=stdout > /tmp/ngrok-test.log 2>&1 &
NGROK_PID=$!
echo "ngrok started (PID: $NGROK_PID)"
sleep 8

# Get ngrok URL
echo ""
echo "Step 5: Retrieving ngrok public URL..."
NGROK_URL=""

for attempt in {1..15}; do
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o 'https://[a-z0-9-]*\.ngrok\.io' | head -1 || echo "")
  
  if [ ! -z "$NGROK_URL" ]; then
    echo "✅ Got ngrok URL on attempt $attempt"
    break
  fi
  
  echo "   Attempt $attempt/15: Checking ngrok API..."
  sleep 1
done

if [ -z "$NGROK_URL" ]; then
  echo "❌ Failed to get ngrok URL!"
  echo ""
  echo "ngrok logs:"
  cat /tmp/ngrok-test.log
  echo ""
  kill $NGROK_PID 2>/dev/null || true
  docker stop $CONTAINER_NAME
  exit 1
fi

echo ""
echo "======================================================================"
echo "                    ✅ NGROK TUNNEL ESTABLISHED ✅"
echo "======================================================================"
echo ""
echo "🌐 PUBLIC URL: $NGROK_URL"
echo ""
echo "Test with curl:"
echo "  curl $NGROK_URL/get"
echo ""
echo "Test in browser:"
echo "  $NGROK_URL/get"
echo "  $NGROK_URL/status/200"
echo "  $NGROK_URL/delay/5"
echo ""
echo "Local access:"
echo "  http://localhost:8888/get"
echo ""
echo "======================================================================"
echo ""
echo "Holding for 2 minutes (120 seconds) for testing..."
echo "Press Ctrl+C to stop"
echo ""

sleep 120

# Cleanup
echo ""
echo "======================================================================"
echo "            Cleaning up ngrok and Docker container..."
echo "======================================================================"
kill $NGROK_PID 2>/dev/null || true
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
sleep 2

echo "✅ Cleanup complete"
echo ""
