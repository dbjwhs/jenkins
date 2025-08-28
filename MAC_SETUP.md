# Mac mini Jenkins Agent Setup Guide

This guide documents the **complete working process** to set up a Mac mini as a Jenkins build agent for native C++ compilation.

## Prerequisites

- Mac mini (M1/M2/Intel)
- macOS Ventura or later
- Admin access to the Mac
- Jenkins running in Docker (using docker-compose)
- Git repository with Jenkins configuration

## Step 1: Update macOS and Developer Tools

### 1.1 Update macOS
```bash
# Check for system updates
sudo softwareupdate --list

# Install all updates
sudo softwareupdate --install --all
```

### 1.2 Install/Update Xcode Command Line Tools
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p
# Should return: /Library/Developer/CommandLineTools
```

### 1.3 Update Homebrew packages
```bash
# Update Homebrew itself
brew update

# Upgrade all packages
brew upgrade

# Clean up old versions
brew cleanup
```

## Step 2: Install Required Software

### 2.1 Install Homebrew (if not present)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2.2 Install Java 17 (REQUIRED - not Java 11!)
```bash
# Install OpenJDK 17
brew install openjdk@17

# Create symlink for system Java
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# Add to shell configuration
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17"' >> ~/.zshrc
source ~/.zshrc

# Verify Java version
java -version
# Should show: openjdk version "17.x.x"
```

### 2.3 Install C++ Build Tools
```bash
# Install build tools
brew install cmake ninja pkg-config git

# Install C++ dependencies
brew install boost openssl capnp googletest

# Verify installations
cmake --version
clang++ --version
ninja --version
```

## Step 3: Configure User Account

We'll use your existing user account (no need to create a jenkins user).

### 3.1 Create Jenkins Agent Directory
```bash
mkdir -p ~/jenkins-agent
```

### 3.2 Enable SSH Access
```bash
# Check if SSH is enabled
sudo systemsetup -getremotelogin

# Enable if needed
sudo systemsetup -setremotelogin on
```

## Step 4: Set Up SSH Authentication

### 4.1 Generate SSH Key Pair
```bash
# Generate SSH key for Jenkins
ssh-keygen -t ed25519 -f ~/.ssh/jenkins_agent_key -N ""

# Add to authorized_keys
cat ~/.ssh/jenkins_agent_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 4.2 Copy Private Key to Jenkins Container
```bash
# Create .ssh directory in Jenkins container
docker exec -u root jenkins-jenkins-1 mkdir -p /var/jenkins_home/.ssh
docker exec -u root jenkins-jenkins-1 chown jenkins:jenkins /var/jenkins_home/.ssh
docker exec -u root jenkins-jenkins-1 chmod 700 /var/jenkins_home/.ssh

# Copy private key to Jenkins container
docker cp ~/.ssh/jenkins_agent_key jenkins-jenkins-1:/var/jenkins_home/.ssh/
docker exec -u root jenkins-jenkins-1 chown jenkins:jenkins /var/jenkins_home/.ssh/jenkins_agent_key
docker exec -u root jenkins-jenkins-1 chmod 600 /var/jenkins_home/.ssh/jenkins_agent_key
```

### 4.3 Test SSH Connection
```bash
# Test from Jenkins container to Mac
docker exec jenkins-jenkins-1 ssh -i /var/jenkins_home/.ssh/jenkins_agent_key \
  -o StrictHostKeyChecking=no $(whoami)@host.docker.internal \
  'echo "✅ SSH connection successful!"'
```

## Step 5: Configure Jenkins

### 5.1 Create Secure Credentials File

**IMPORTANT**: Never store private keys in Git! Create a separate credentials file:

1. **On your Mac mini**, create `jenkins-credentials.yaml` (next to docker-compose.yaml):

```yaml
# Jenkins Credentials - DO NOT COMMIT TO GIT
credentials:
  system:
    domainCredentials:
      - credentials:
          - basicSSHUserPrivateKey:
              scope: GLOBAL
              id: "mac-mini-ssh"
              username: "YOUR_MAC_USERNAME"  # Replace with your username
              description: "SSH key for Mac mini M2 agent"
              privateKeySource:
                directEntry:
                  privateKey: |
                    -----BEGIN OPENSSH PRIVATE KEY-----
                    YOUR_PRIVATE_KEY_CONTENT_HERE
                    -----END OPENSSH PRIVATE KEY-----
```

2. **Add to .gitignore** (this is already done):
```
jenkins-credentials.yaml
*-credentials.yaml
*.pem
*.key
```

### 5.2 Update jenkins.yaml

The main `jenkins.yaml` now references the external credentials file:

jenkins:
  nodes:
    - permanent:
        name: "mac-mini-m2"
        labelString: "macos m2 arm64 native"
        mode: NORMAL
        numExecutors: 4
        remoteFS: "/Users/YOUR_MAC_USERNAME/jenkins-agent"  # Replace with your path
        launcher:
          ssh:
            host: "host.docker.internal"
            port: 22
            credentialsId: "mac-mini-ssh"
            launchTimeoutSeconds: 60
            maxNumRetries: 3
            retryWaitTime: 30
            sshHostKeyVerificationStrategy:
              manuallyTrustedKeyVerificationStrategy:
                requireInitialManualTrust: false
        nodeProperties:
          - envVars:
              env:
                - key: "HOMEBREW_PREFIX"
                  value: "/opt/homebrew"
                - key: "PATH"
                  value: "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
                - key: "CMAKE_PREFIX_PATH"
                  value: "/opt/homebrew"
        retentionStrategy:
          always: {}
```

### 5.3 Create .env File (WORKING SOLUTION)

**IMPORTANT**: Create a `.env` file in your Jenkins directory (next to docker-compose.yaml):

```bash
# .env file content:
# Jenkins Environment Variables - DO NOT COMMIT TO GIT
MAC_MINI_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT_FROM_jenkins_agent_key
-----END OPENSSH PRIVATE KEY-----"
```

### 5.4 Update docker-compose.yaml (WORKING SOLUTION)

The docker-compose.yaml should mount the SSH key file directly and load the .env file:

```yaml
volumes:
  - jenkins_home:/var/jenkins_home
  - /var/run/docker.sock:/var/run/docker.sock
  - ./jobs.groovy:/var/jenkins_home/jobs.groovy:ro
  - ./jenkins.yaml:/var/jenkins_home/jenkins.yaml:ro
  - ~/.ssh/jenkins_agent_key:/var/jenkins_home/.ssh/jenkins_agent_key:ro
env_file:
  - .env
```

**Key Points:**
- The SSH key file is mounted directly from Mac to Jenkins container
- The .env file provides environment variable for JCasC configuration
- Both approaches work together for maximum reliability

### 5.5 Fix SSH Key Permissions (CRITICAL STEP)

After mounting the SSH key, fix the permissions in the Jenkins container:

```bash
# Set proper ownership and permissions for the mounted SSH key
docker exec -u root jenkins-jenkins-1 chown jenkins:jenkins /var/jenkins_home/.ssh/jenkins_agent_key
docker exec -u root jenkins-jenkins-1 chmod 600 /var/jenkins_home/.ssh/jenkins_agent_key

# Test SSH connection from Jenkins container
docker exec jenkins-jenkins-1 ssh -o StrictHostKeyChecking=no -i /var/jenkins_home/.ssh/jenkins_agent_key dbjones@host.docker.internal 'echo "SSH test successful"'
```

### 5.6 Restart Jenkins
```bash
docker-compose restart jenkins
```

**WORKING SOLUTION**: The agent connects automatically with persistent SSH key mounting and proper permissions!

## Step 6: Update Pipeline Jobs

Update your pipeline jobs to use the Mac agent:

```groovy
pipeline {
    agent { label 'mac-mini-m2' }
    // ... rest of pipeline
}
```

## Step 7: Verify Connection

1. Go to **Manage Jenkins → Manage Nodes**
2. Click on **mac-mini-m2**
3. Should show "Agent successfully connected and online"
4. If not, click "Relaunch agent"

## Troubleshooting

### Issue: "jenkins user already exists" error
```bash
# This happens when a corrupted user record exists
# Solution: Use your existing account instead of creating jenkins user
```

### Issue: Java version error
```
UnsupportedClassVersionError: class file version 61.0
```
**Solution**: Install Java 17, not Java 11. Jenkins 2.479+ requires Java 17.

### Issue: SSH Authentication Failed
- Verify SSH is enabled: `sudo systemsetup -getremotelogin`
- Check key permissions: `ls -la ~/.ssh/`
- Ensure authorized_keys has correct permissions: `chmod 600 ~/.ssh/authorized_keys`
- Test manual SSH: `ssh $(whoami)@localhost`

### Issue: Agent won't connect
1. Check Jenkins container logs: `docker-compose logs jenkins`
2. Verify `host.docker.internal` resolves
3. Check firewall settings
4. Ensure Java is in PATH

### Issue: Build tools not found
```bash
# Ensure Homebrew is in PATH
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Environment Variables

The agent sets these environment variables:
- `HOMEBREW_PREFIX=/opt/homebrew`
- `PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`
- `CMAKE_PREFIX_PATH=/opt/homebrew`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17`

## Security Notes

- **SSH key authentication only** (no passwords)
- **Private keys NOT stored in Git** - uses external credentials file
- Agent runs under your user account (principle of least privilege)
- Jenkins accesses via Docker's host.docker.internal
- Credentials file is mounted read-only and excluded from Git
- Private key permissions: 600 (owner read/write only)

## Performance Benefits

- Native ARM64 compilation (no emulation)
- Direct hardware access
- No Docker overhead for builds
- Full utilization of Apple Silicon
- Parallel execution with 4 executors

## Quick Setup Script

For future Mac setups, use the provided script:
```bash
./setup-mac-agent-alternative.sh
```

This automates most of the setup process using your current user account.

## Verification Commands

```bash
# Check Java version
java -version  # Should show 17

# Check build tools
cmake --version
clang++ --version
brew list

# Check SSH
ssh $(whoami)@localhost 'echo "SSH works"'

# Check agent directory
ls -la ~/jenkins-agent/
```

## Success Indicators

✅ Jenkins node shows "Agent successfully connected and online"  
✅ 4 executors available on mac-mini-m2  
✅ Builds show "Running on mac-mini-m2"  
✅ C++ projects compile with native tools  
✅ No Docker containers for build execution  

---

**Last Updated**: Successfully tested on macOS Sonoma with Jenkins 2.479 LTS
