#!/bin/bash

# Fix partial or corrupted jenkins user record on macOS
# This handles the case where dscl shows the user exists but id doesn't find it

set -e

echo "🔧 Fixing Jenkins user account issues"
echo "====================================="

JENKINS_USER="jenkins"

echo "Step 1: Checking for existing jenkins user records"

# Check using dscl (Directory Service)
echo "Checking Directory Service records..."
if dscl . -list /Users | grep -q "^jenkins$"; then
    echo "⚠️  Found jenkins in Directory Service"
    echo "Details:"
    dscl . -read /Users/jenkins 2>/dev/null || echo "Cannot read user details"
    
    echo ""
    echo "Attempting to remove corrupted user record..."
    echo "This requires admin privileges"
    
    # Remove the corrupted user record
    sudo dscl . -delete /Users/jenkins 2>/dev/null && echo "✅ Removed old user record" || echo "⚠️  Could not remove user record"
else
    echo "✅ No jenkins user in Directory Service"
fi

echo ""
echo "Step 2: Checking for home directory"
if [ -d "/Users/jenkins" ]; then
    echo "⚠️  Found existing /Users/jenkins directory"
    echo "Contents:"
    ls -la /Users/jenkins/ 2>/dev/null || echo "Cannot list contents"
    
    echo ""
    echo "Do you want to backup and remove this directory? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        # Backup the directory
        if [ "$(ls -A /Users/jenkins 2>/dev/null)" ]; then
            sudo mv /Users/jenkins /Users/jenkins.backup.$(date +%Y%m%d-%H%M%S)
            echo "✅ Backed up existing directory"
        else
            sudo rm -rf /Users/jenkins
            echo "✅ Removed empty directory"
        fi
    else
        echo "⚠️  Keeping existing directory - this may cause issues"
    fi
else
    echo "✅ No existing home directory"
fi

echo ""
echo "Step 3: Creating fresh jenkins user"
echo "Creating user with proper settings..."

# Create the user properly
sudo dscl . -create /Users/jenkins
sudo dscl . -create /Users/jenkins UserShell /bin/bash
sudo dscl . -create /Users/jenkins RealName "Jenkins Agent"
sudo dscl . -create /Users/jenkins UniqueID 502
sudo dscl . -create /Users/jenkins PrimaryGroupID 20
sudo dscl . -create /Users/jenkins NFSHomeDirectory /Users/jenkins

# Create home directory
sudo mkdir -p /Users/jenkins
sudo createhomedir -c -u jenkins
sudo chown -R jenkins:staff /Users/jenkins

echo "✅ User created successfully"

echo ""
echo "Step 4: Setting password for jenkins user"
echo "Enter a password for the jenkins user:"
sudo passwd jenkins

echo ""
echo "Step 5: Verifying user creation"
if id jenkins &>/dev/null; then
    echo "✅ User verified with id command:"
    id jenkins
else
    echo "❌ User still not showing in id command"
    echo "Try logging out and back in, or restart the system"
fi

echo ""
echo "🎉 User fix complete!"
echo ""
echo "Next steps:"
echo "1. If the user still doesn't show, restart your Mac"
echo "2. Run ./setup-mac-agent.sh to continue setup"
echo "3. The jenkins user password has been set"
