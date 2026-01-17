# Local ngrok Testing Guide

## Overview

This guide helps you test ngrok locally before using it in GitHub Actions. ngrok creates a secure tunnel from your local machine to the internet, giving you a public URL.

## Prerequisites

1. **ngrok Account** (free tier available)
   - Sign up at: https://ngrok.com
   - Download ngrok for your OS from: https://ngrok.com/download

2. **ngrok Authtoken** 
   - After signup, get your authtoken from: https://dashboard.ngrok.com/auth
   - Install: `ngrok config add-authtoken <YOUR_TOKEN>`

## Step 1: Install ngrok

### Windows
```bash
# Option 1: Using Chocolatey
choco install ngrok

# Option 2: Using Scoop
scoop install ngrok

# Option 3: Manual download
# Download from https://ngrok.com/download
# Extract ngrok.exe
# Add folder to PATH or run directly as ./ngrok.exe
```

### Linux
```bash
# Download (choose your architecture)
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
unzip ngrok-v3-stable-linux-amd64.zip
sudo mv ngrok /usr/local/bin/
```

### macOS
```bash
brew install ngrok
# OR download from https://ngrok.com/download
```

## Step 2: Authenticate ngrok

```bash
ngrok config add-authtoken <YOUR_AUTHTOKEN>
```

You can get your authtoken from: https://dashboard.ngrok.com/auth

## Step 3: Test ngrok Locally

### Method 1: Using Python HTTP Server (Simplest)

```bash
# Terminal 1: Start Python server on port 9999
cd /tmp
python3 -m http.server 9999

# Terminal 2: Test direct access
curl http://localhost:9999

# Terminal 3: Start ngrok tunnel
ngrok http 9999

# You'll see output like:
# Session Status                online
# Web Interface                 http://127.0.0.1:4040
# Forwarding                    https://xxxx-xxxx-xxxx.ngrok.io -> http://localhost:9999
```

### Method 2: Using Your Spring Boot App Locally

```bash
# Terminal 1: Start your Spring Boot app
cd app/sample-spring-boot-app
mvn spring-boot:run

# Terminal 2: Start ngrok tunnel to port 8080
ngrok http 8080

# You'll get a public URL like: https://xxxx-xxxx-xxxx.ngrok.io
```

### Method 3: Using Kind Cluster

```bash
# Terminal 1: Deploy to Kind
kubectl create namespace dev
helm install my-stack ./helm-chart -n dev

# Terminal 2: Port-forward the service
kubectl port-forward -n dev svc/spring-app-service 8080:8080

# Terminal 3: Start ngrok tunnel
ngrok http 8080

# You'll get a public URL for your Kubernetes app
```

## Step 4: Test the Public URL

Once ngrok is running, you'll see:

```
Session Status                online
Web Interface                 http://127.0.0.1:4040
Forwarding                    https://xxxx-yyyy-zzzz.ngrok.io -> http://localhost:8080
```

### Test with curl

```bash
# Get requests
curl https://xxxx-yyyy-zzzz.ngrok.io/api/messages

# Post requests
curl -X POST -H "Content-Type: text/plain" \
  -d "test message" \
  https://xxxx-yyyy-zzzz.ngrok.io/api/messages

# Replace xxxx-yyyy-zzzz with your actual ngrok subdomain
```

### Test in Browser

Simply open in your browser:
```
https://xxxx-yyyy-zzzz.ngrok.io/api/messages
```

### Check ngrok Status

Open ngrok web interface:
```
http://127.0.0.1:4040
```

Shows:
- Active connections
- Request/response details
- Tunnel statistics
- Replay function

## Step 5: Stop ngrok

Press `Ctrl+C` in the terminal where ngrok is running.

## Troubleshooting

### "ngrok command not found"
- Ensure ngrok is installed and in your PATH
- Try: `which ngrok` (Linux/Mac) or `where ngrok` (Windows)
- Or run with full path: `/path/to/ngrok http 8080`

### "ERR_NGROK_100 Authentication failed"
- Make sure you've authenticated: `ngrok config add-authtoken <TOKEN>`
- Get token from: https://dashboard.ngrok.com/auth

### "bind: permission denied" on Linux
- Use a port > 1024 (not 80 or 443)
- Or run with sudo

### Port already in use
- Find process: `lsof -i :8080` (Linux/Mac)
- Kill process: `kill -9 <PID>`
- Or use a different port

### ngrok shows "offlinemode" or "no active sessions"
- Check internet connection
- Re-authenticate: `ngrok config add-authtoken <TOKEN>`

## Next Steps

Once you've verified ngrok works locally:

1. The GitHub Actions workflow will use the same approach
2. ngrok URL will be displayed in workflow logs
3. 5-minute testing window allows you to verify deployment
4. All logs are captured for review

## GitHub Actions Integration

The workflow automatically:
- Installs ngrok
- Authenticates (using GitHub Secrets)
- Starts port-forward
- Creates ngrok tunnel
- Displays public URL
- Waits 5 minutes for testing
- Cleans up

---

**Questions?**
- ngrok docs: https://ngrok.com/docs
- Troubleshooting: https://ngrok.com/docs/guides/troubleshooting/
