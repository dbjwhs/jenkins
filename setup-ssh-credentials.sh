#!/bin/bash

# Script to set up SSH key authentication between Jenkins container and Mac mini
# Run this script on the Mac mini after running setup-mac-agent.sh

set -e

echo "🔑 Setting up SSH Key Authentication"
echo "===================================="

JENKINS_USER="jenkins"
CONTAINER_NAME="jenkins-jenkins-1"

echo "Step 1: Generating SSH key pair for Jenkins agent"
if [ ! -f /Users/jenkins/.ssh/jenkins_agent_key ]; then
    sudo -u jenkins ssh-keygen -t ed25519 -f /Users/jenkins/.ssh/jenkins_agent_key -N "" -C "jenkins-agent@mac-mini"
    echo "✅ SSH key pair generated"
else
    echo "✅ SSH key pair already exists"
fi

echo "Step 2: Setting up authorized_keys"
sudo -u jenkins cp /Users/jenkins/.ssh/jenkins_agent_key.pub /Users/jenkins/.ssh/authorized_keys
sudo -u jenkins chmod 600 /Users/jenkins/.ssh/authorized_keys
echo "✅ Public key added to authorized_keys"

echo "Step 3: Copying private key to Jenkins container"
echo "This will copy the private key to the Jenkins container for authentication"

# Copy the private key to Jenkins container
docker exec -u root $CONTAINER_NAME mkdir -p /var/jenkins_home/.ssh
docker cp /Users/jenkins/.ssh/jenkins_agent_key $CONTAINER_NAME:/var/jenkins_home/.ssh/
docker exec -u root $CONTAINER_NAME chown jenkins:jenkins /var/jenkins_home/.ssh/jenkins_agent_key
docker exec -u root $CONTAINER_NAME chmod 600 /var/jenkins_home/.ssh/jenkins_agent_key

echo "✅ Private key copied to Jenkins container"

echo "Step 4: Testing SSH connection"
echo "Testing connection from Jenkins container to Mac mini..."

# Test the connection
docker exec $CONTAINER_NAME ssh -i /var/jenkins_home/.ssh/jenkins_agent_key -o StrictHostKeyChecking=no jenkins@host.docker.internal 'echo "SSH connection successful!"'

if [ $? -eq 0 ]; then
    echo "✅ SSH connection test successful!"
else
    echo "❌ SSH connection test failed. Please check the configuration."
    exit 1
fi

echo ""
echo "🎉 SSH Authentication Setup Complete!"
echo "===================================="
echo ""
echo "Next steps:"
echo "1. Update the jenkins.yaml credentials section with the SSH private key"
echo "2. The credential should reference: /var/jenkins_home/.ssh/jenkins_agent_key"
echo "3. Restart Jenkins to apply the new configuration"
echo ""
echo "SSH key locations:"
echo "- Private key (in container): /var/jenkins_home/.ssh/jenkins_agent_key"
echo "- Public key (on Mac): /Users/jenkins/.ssh/jenkins_agent_key.pub"
echo "- Authorized keys: /Users/jenkins/.ssh/authorized_keys"
