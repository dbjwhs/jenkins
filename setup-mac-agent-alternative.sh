#!/bin/bash

# Alternative setup using your current user account instead of creating jenkins user
# This avoids user creation issues entirely

set -e

echo "🔧 Alternative Mac mini M2 Jenkins Agent Setup"
echo "=============================================="
echo "This setup uses your current user account instead of creating a jenkins user"
echo ""

# Configuration
CURRENT_USER=$(whoami)
AGENT_DIR="$HOME/jenkins-agent"
JAVA_VERSION="11"

echo "Setting up Jenkins agent for user: $CURRENT_USER"
echo "Agent directory: $AGENT_DIR"
echo ""

echo "Step 1: Installing required software"

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installed"
else
    echo "✅ Homebrew already installed"
fi

# Install Java
if ! java --version 2>&1 | grep -q "openjdk"; then
    echo "Installing OpenJDK..."
    brew install openjdk@${JAVA_VERSION}
    sudo ln -sfn /opt/homebrew/opt/openjdk@${JAVA_VERSION}/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-${JAVA_VERSION}.jdk 2>/dev/null || true
    echo "✅ Java installed"
else
    echo "✅ Java already installed"
fi

# Install development tools
echo "Installing development tools..."
brew list cmake &>/dev/null || brew install cmake
brew list ninja &>/dev/null || brew install ninja
brew list pkg-config &>/dev/null || brew install pkg-config
brew list git &>/dev/null || brew install git
brew list capnproto &>/dev/null || brew install capnproto
brew list boost &>/dev/null || brew install boost
brew list openssl &>/dev/null || brew install openssl

echo "✅ Development tools installed"

# Install Xcode Command Line Tools if not present
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode Command Line Tools installation and re-run this script."
    exit 1
else
    echo "✅ Xcode Command Line Tools already installed"
fi

echo ""
echo "Step 2: Setting up agent directory"
mkdir -p "$AGENT_DIR"
echo "✅ Agent directory created: $AGENT_DIR"

echo ""
echo "Step 3: Setting up SSH access (if not already enabled)"
echo "Checking SSH status..."
if ! sudo systemsetup -getremotelogin | grep -q "On"; then
    echo "Enabling SSH..."
    sudo systemsetup -setremotelogin on
    echo "✅ SSH enabled"
else
    echo "✅ SSH already enabled"
fi

echo ""
echo "Step 4: Creating Jenkins environment script"
cat << EOF > "$AGENT_DIR/jenkins-env.sh"
#!/bin/bash
# Jenkins Agent Environment for $CURRENT_USER

export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CMAKE_PREFIX_PATH="/opt/homebrew"
export JAVA_HOME="/opt/homebrew/opt/openjdk@${JAVA_VERSION}"
export PATH="\$JAVA_HOME/bin:\$PATH"

# C++ Build Environment
export BOOST_ROOT="\$(brew --prefix boost 2>/dev/null)"
export OPENSSL_ROOT_DIR="\$(brew --prefix openssl 2>/dev/null)"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig"

echo "Jenkins Agent environment loaded for $CURRENT_USER"
EOF

chmod +x "$AGENT_DIR/jenkins-env.sh"
echo "✅ Environment script created"

echo ""
echo "🎉 Alternative Agent Setup Complete!"
echo "====================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Update jenkins.yaml to use your current user:"
echo "   - Change username from 'jenkins' to '$CURRENT_USER'"
echo "   - Change remoteFS to '$AGENT_DIR'"
echo ""
echo "2. Set up SSH key authentication:"
echo "   - Generate SSH key: ssh-keygen -t ed25519 -f ~/.ssh/jenkins_agent_key"
echo "   - Add to authorized_keys: cat ~/.ssh/jenkins_agent_key.pub >> ~/.ssh/authorized_keys"
echo "   - Copy private key to Jenkins container"
echo ""
echo "3. Test connection from Jenkins container:"
echo "   docker exec jenkins-jenkins-1 ssh $CURRENT_USER@host.docker.internal"
echo ""
echo "Agent configuration:"
echo "- User: $CURRENT_USER"
echo "- Agent directory: $AGENT_DIR"
echo "- Environment script: $AGENT_DIR/jenkins-env.sh"
echo ""
echo "Your regular user account will be used for Jenkins builds."
