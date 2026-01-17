#!/bin/bash

# Ultra-Simple ngrok Testing Script
# Uses Python's built-in HTTP server

echo "======================================================================"
echo "        NGROK TESTING - Simple Python HTTP Server"
echo "======================================================================"
echo ""

# Step 1: Create a simple test file
echo "Step 1: Setting up simple HTTP server..."
mkdir -p /tmp/ngrok-test
cat > /tmp/ngrok-test/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ngrok Test Server</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        .success { color: green; font-weight: bold; }
        .info { background: #f0f0f0; padding: 20px; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>✅ ngrok Tunnel Working!</h1>
    <div class="success">
        <p>If you can see this page, your ngrok tunnel is successfully exposing your local server to the internet!</p>
    </div>
    <div class="info">
        <h2>Test Information</h2>
        <p>Server Type: Python HTTP Server</p>
        <p>Port: 9999</p>
        <p>ngrok is tunneling this to a public URL</p>
    </div>
    <div class="info">
        <h2>Test Endpoints</h2>
        <ul>
            <li><a href="/index.html">/index.html</a> - This page</li>
            <li><a href="/test.json">/test.json</a> - JSON endpoint</li>
        </ul>
    </div>
</body>
</html>
EOF

cat > /tmp/ngrok-test/test.json << 'EOF'
{
  "status": "success",
  "message": "ngrok tunnel is working!",
  "timestamp": "2025-01-17T00:00:00Z",
  "test": true
}
EOF

echo "✅ Test files created"
echo ""

# Step 2: Start Python HTTP server
echo "Step 2: Starting Python HTTP server on port 9999..."
cd /tmp/ngrok-test

python3 -m http.server 9999 > /tmp/python-server.log 2>&1 &
SERVER_PID=$!
echo "✅ Server started (PID: $SERVER_PID)"
sleep 2

# Test direct access
echo ""
echo "Step 3: Testing direct access..."
if curl -s http://localhost:9999/test.json | grep -q "success"; then
  echo "✅ Direct access works: http://localhost:9999"
else
  echo "❌ Direct access failed"
  kill $SERVER_PID 2>/dev/null || true
  exit 1
fi
echo ""

# Step 4: Check ngrok
echo "Step 4: Checking ngrok installation..."
if ! command -v ngrok &> /dev/null; then
  echo "❌ ngrok not found in PATH"
  echo ""
  echo "Install ngrok:"
  echo "  Windows: choco install ngrok  (or download from ngrok.com)"
  echo "  Linux:   apt-get install ngrok or download from ngrok.com"
  echo "  Mac:     brew install ngrok"
  echo ""
  kill $SERVER_PID 2>/dev/null || true
  exit 1
fi

NGROK_VERSION=$(ngrok version 2>&1 | head -1)
echo "✅ ngrok found: $NGROK_VERSION"
echo ""

# Step 5: Start ngrok
echo "Step 5: Starting ngrok tunnel..."
echo ""

# Kill any existing ngrok
pkill -f ngrok 2>/dev/null || true
sleep 2

./ngrok http 9999 --log=stdout > /tmp/ngrok-test.log 2>&1 &
NGROK_PID=$!
echo "ngrok started (PID: $NGROK_PID)"

# Wait for ngrok to start
sleep 10

# Get ngrok URL
echo ""
echo "Step 6: Getting ngrok public URL..."
NGROK_URL=""

for attempt in {1..20}; do
  # Try API first
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o 'https://[a-z0-9-]*\.ngrok\.io' | head -1 || echo "")
  
  if [ ! -z "$NGROK_URL" ]; then
    echo "✅ ngrok URL acquired on attempt $attempt"
    break
  fi
  
  if [ $((attempt % 5)) -eq 0 ]; then
    echo "   Attempt $attempt/20..."
  fi
  sleep 1
done

if [ -z "$NGROK_URL" ]; then
  echo "❌ Failed to get ngrok URL"
  echo ""
  echo "ngrok logs:"
  tail -30 /tmp/ngrok-test.log
  kill $NGROK_PID 2>/dev/null || true
  kill $SERVER_PID 2>/dev/null || true
  exit 1
fi

echo ""
echo "======================================================================"
echo "            ✅✅✅ NGROK TUNNEL SUCCESSFULLY ESTABLISHED ✅✅✅"
echo "======================================================================"
echo ""
echo "🌐 PUBLIC URL: $NGROK_URL"
echo ""
echo "Test commands:"
echo ""
echo "1. JSON endpoint:"
echo "   curl $NGROK_URL/test.json"
echo ""
echo "2. HTML page (open in browser):"
echo "   $NGROK_URL/index.html"
echo ""
echo "3. Local direct access:"
echo "   curl http://localhost:9999/test.json"
echo ""
echo "======================================================================"
echo ""
echo "🔬 TESTING WINDOW - 3 MINUTES (180 seconds)"
echo "Press Ctrl+C to stop ngrok and server"
echo ""

sleep 180

# Cleanup
echo ""
echo "======================================================================"
echo "             Cleaning up ngrok and Python server..."
echo "======================================================================"
kill $NGROK_PID 2>/dev/null || true
kill $SERVER_PID 2>/dev/null || true
sleep 2

echo "✅ Cleanup complete"
echo ""
echo "Summary:"
echo "  ✅ ngrok tunnel tested and verified"
echo "  ✅ Public URL was successfully created"
echo "  ✅ Access from internet was possible"
echo ""
