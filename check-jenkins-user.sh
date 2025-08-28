#!/bin/bash

# Check and fix Jenkins user setup
# Run this if the jenkins user already exists but setup is incomplete

set -e

JENKINS_USER="jenkins"
AGENT_DIR="/Users/jenkins/agent"

echo "🔍 Checking Jenkins user status"
echo "=============================="

# Check if user exists
if id "$JENKINS_USER" &>/dev/null; then
    echo "✅ Jenkins user exists"
    
    # Get user info
    echo "User details:"
    id jenkins
    echo "Home directory: $(dscl . -read /Users/jenkins NFSHomeDirectory | cut -d' ' -f2)"
    
    # Check home directory
    if [ -d "/Users/jenkins" ]; then
        echo "✅ Home directory exists"
        echo "Contents:"
        ls -la /Users/jenkins/ || echo "Cannot list contents (permission denied)"
    else
        echo "❌ Home directory missing - creating it"
        sudo createhomedir -c -u jenkins
    fi
    
    # Check agent directory
    if [ -d "$AGENT_DIR" ]; then
        echo "✅ Agent directory exists: $AGENT_DIR"
    else
        echo "❌ Agent directory missing - creating it"
        sudo -u jenkins mkdir -p "$AGENT_DIR"
    fi
    
    # Check SSH directory
    if [ -d "/Users/jenkins/.ssh" ]; then
        echo "✅ SSH directory exists"
        echo "SSH files:"
        sudo -u jenkins ls -la /Users/jenkins/.ssh/ 2>/dev/null || echo "No SSH files yet"
    else
        echo "❌ SSH directory missing - creating it"
        sudo -u jenkins mkdir -p /Users/jenkins/.ssh
        sudo -u jenkins chmod 700 /Users/jenkins/.ssh
    fi
    
    # Check if user can log in
    echo ""
    echo "Testing jenkins user shell access..."
    sudo -u jenkins whoami && echo "✅ Jenkins user shell works" || echo "❌ Jenkins user shell issue"
    
else
    echo "❌ Jenkins user does not exist"
    exit 1
fi

echo ""
echo "Continue with the main setup script, skipping user creation..."
