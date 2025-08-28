#!/bin/bash

# Jenkins Mac mini M2 Agent Setup Script
# Run this script on the Mac mini to prepare it as a Jenkins agent

set -e

echo "🔧 Setting up Mac mini M2 as Jenkins Agent"
echo "=========================================="

# Configuration
JENKINS_USER="jenkins"
AGENT_DIR="/Users/jenkins/agent"
JAVA_VERSION="11"

echo "Step 1: Checking Jenkins user account"
if ! id "$JENKINS_USER" &>/dev/null; then
    echo "Creating jenkins user account..."
    
    # Create jenkins user
    sudo dscl . -create /Users/jenkins
    sudo dscl . -create /Users/jenkins UserShell /bin/bash
    sudo dscl . -create /Users/jenkins RealName "Jenkins Agent"
    sudo dscl . -create /Users/jenkins UniqueID 502
    sudo dscl . -create /Users/jenkins PrimaryGroupID 20
    sudo dscl . -create /Users/jenkins NFSHomeDirectory /Users/jenkins
    
    # Create home directory
    sudo createhomedir -c -u jenkins
    
    # Set password (you'll need to enter this when prompted)
    echo "Setting password for jenkins user (enter a secure password):"
    sudo passwd jenkins
    
    echo "✅ Jenkins user created"
else
    echo "✅ Jenkins user already exists"
    
    # Ensure home directory exists
    if [ ! -d "/Users/jenkins" ]; then
        echo "Creating missing home directory..."
        sudo createhomedir -c -u jenkins
    fi
    
    # Check if user needs password set
    echo "If you haven't set a password for the jenkins user yet, you can do so now:"
    echo "sudo passwd jenkins"
    echo "Press Enter to continue or Ctrl+C to set password first..."
    read -r
fi

echo "Step 2: Installing required software"

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installed"
else
    echo "✅ Homebrew already installed"
fi

# Install Java
echo "Installing OpenJDK..."
brew install openjdk@${JAVA_VERSION}
sudo ln -sfn /opt/homebrew/opt/openjdk@${JAVA_VERSION}/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-${JAVA_VERSION}.jdk

# Install development tools
echo "Installing development tools..."
brew install cmake ninja pkg-config git
brew install capnproto boost openssl

# Install Xcode Command Line Tools if not present
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode Command Line Tools installation and re-run this script."
    exit 1
else
    echo "✅ Xcode Command Line Tools already installed"
fi

echo "Step 3: Setting up agent directory"
sudo -u jenkins mkdir -p "$AGENT_DIR"
sudo chown jenkins:staff "$AGENT_DIR"
echo "✅ Agent directory created: $AGENT_DIR"

echo "Step 4: Configuring SSH access"
sudo -u jenkins mkdir -p /Users/jenkins/.ssh
sudo -u jenkins chmod 700 /Users/jenkins/.ssh

if [ ! -f /Users/jenkins/.ssh/authorized_keys ]; then
    sudo -u jenkins touch /Users/jenkins/.ssh/authorized_keys
    sudo -u jenkins chmod 600 /Users/jenkins/.ssh/authorized_keys
    echo "✅ SSH authorized_keys file created"
    echo "📝 Remember to add your Jenkins controller's public key to /Users/jenkins/.ssh/authorized_keys"
else
    echo "✅ SSH already configured"
fi

echo "Step 5: Enable SSH on macOS"
sudo systemsetup -setremotelogin on
echo "✅ SSH remote login enabled"

echo "Step 6: Setting up environment"
cat << 'EOF' | sudo -u jenkins tee /Users/jenkins/.bash_profile
# Jenkins Agent Environment
export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CMAKE_PREFIX_PATH="/opt/homebrew"
export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
export PATH="$JAVA_HOME/bin:$PATH"

# C++ Build Environment
export BOOST_ROOT="$(brew --prefix boost)"
export OPENSSL_ROOT_DIR="$(brew --prefix openssl)"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig"

echo "Jenkins Agent environment loaded"
EOF

echo "✅ Environment configured"

echo ""
echo "🎉 Mac mini Jenkins Agent Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Update jenkins.yaml with the correct SSH credentials"
echo "2. Add the Jenkins controller's SSH public key to:"
echo "   /Users/jenkins/.ssh/authorized_keys"
echo "3. Test SSH connection from the Jenkins container:"
echo "   ssh jenkins@host.docker.internal"
echo "4. Restart Jenkins to apply the new agent configuration"
echo ""
echo "Agent details:"
echo "- User: jenkins"
echo "- Home: /Users/jenkins"
echo "- Agent directory: $AGENT_DIR"
echo "- Java: $(java --version | head -n1)"
echo "- SSH: Enabled"
echo ""
echo "To test the environment:"
echo "su - jenkins -c 'cmake --version && clang++ --version'"
