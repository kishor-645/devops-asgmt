#!/bin/bash

# Simple script to extract and display Jenkins admin password

echo "Extracting Jenkins admin password..."
echo ""

# Try to get password from Docker logs
password=$(docker logs jenkins-ci 2>&1 | grep -oP '(?<=)\w{32}(?=)' | head -1)

if [ -z "$password" ]; then
    # Try to get directly from container
    password=$(docker exec jenkins-ci cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null)
fi

if [ -z "$password" ]; then
    echo "Could not retrieve password. Showing logs:"
    docker logs jenkins-ci | grep -A 5 "initialAdminPassword"
else
    echo "Jenkins Admin Password:"
    echo "$password"
fi
