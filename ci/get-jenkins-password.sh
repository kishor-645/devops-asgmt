#!/bin/bash

# Simple script to extract and display Jenkins admin password

echo "Extracting Jenkins admin password..."
echo ""

# Extract password from Docker logs - it's a 32-character hex string
password=$(docker logs jenkins-ci 2>&1 | grep -A 2 "Please use the following password" | tail -1 | tr -d '[LF]>' | xargs)

if [ -z "$password" ] || [ "$password" == "" ]; then
    echo "❌ Could not retrieve password. Jenkins might not be fully started yet."
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Wait 2-3 minutes for Jenkins to fully start"
    echo "2. Check if container is running: docker ps | grep jenkins"
    echo "3. View logs: docker logs jenkins-ci"
    echo ""
    echo "Manual commands to try:"
    echo "  docker logs jenkins-ci 2>&1 | grep -A 3 'password generated'"
else
    echo "✅ Jenkins Admin Password:"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$password"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Open browser: http://localhost:8082"
fi
