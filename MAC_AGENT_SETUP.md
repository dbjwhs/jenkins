# Mac mini M2 Jenkins Agent Setup

This document describes how to configure the Mac mini M2 as a Jenkins agent for native C++ builds.

## Overview

The Mac mini will be configured as a permanent Jenkins agent with:
- SSH connection from Jenkins container
- Native macOS development environment
- Homebrew-managed dependencies
- Labels: `macos`, `m2`, `arm64`, `native`

## Quick Setup

### 1. Run the Setup Script on Mac mini

```bash
# On the Mac mini
./setup-mac-agent.sh
```

This script will:
- Create a `jenkins` user account
- Install required development tools (Homebrew, Java, CMake, etc.)
- Set up the agent directory
- Configure SSH access
- Install C++ build dependencies

### 2. Set up SSH Key Authentication

```bash
# On the Mac mini
./setup-ssh-credentials.sh
```

This script will:
- Generate SSH key pair for the jenkins user
- Set up authorized_keys for SSH access
- Copy the private key to the Jenkins container
- Test the SSH connection

### 3. Update Jenkins Configuration

The `jenkins.yaml` file has been updated with:
- Mac mini agent configuration
- SSH credentials placeholder
- Environment variables for native builds

### 4. Restart Jenkins

After completing the setup:
```bash
# On the Mac mini (where Jenkins runs)
docker-compose restart jenkins
```

## Manual Configuration Steps

If you need to set up the credentials manually:

1. Go to **Manage Jenkins > Manage Credentials**
2. Update the `mac-mini-ssh` credential with the private key content from `/Users/jenkins/.ssh/jenkins_agent_key`
3. Or use the Jenkins UI to create a new SSH credential

## Agent Configuration Details

### Node Properties
- **Name**: `mac-mini-m2`
- **Labels**: `macos m2 arm64 native`
- **Executors**: 4
- **Remote FS**: `/Users/jenkins/agent`
- **Connection**: SSH to `host.docker.internal:22`

### Environment Variables
- `HOMEBREW_PREFIX=/opt/homebrew`
- `PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`
- `CMAKE_PREFIX_PATH=/opt/homebrew`

### Development Tools
- **Compiler**: Apple Clang (latest Xcode Command Line Tools)
- **Build System**: CMake + Ninja
- **Package Manager**: Homebrew
- **Dependencies**: Boost, OpenSSL, Cap'n Proto

## Pipeline Updates

The C++ pipelines have been updated to:
- Use `agent { label 'mac-mini-m2' }` instead of Docker
- Install dependencies via Homebrew
- Use native macOS build tools
- Leverage Apple Silicon optimizations

## Verification

### Test SSH Connection
```bash
# From inside Jenkins container
docker exec jenkins-jenkins-1 ssh jenkins@host.docker.internal 'echo "Connection successful"'
```

### Test Build Environment
```bash
# On Mac mini as jenkins user
su - jenkins -c 'cmake --version && clang++ --version && brew list'
```

### Test Agent Connection
1. Go to **Manage Jenkins > Manage Nodes**
2. Look for `mac-mini-m2` agent
3. Check connection status and logs

## Troubleshooting

### SSH Connection Issues
- Verify SSH is enabled: `sudo systemsetup -getremotelogin`
- Check SSH key permissions: `ls -la /Users/jenkins/.ssh/`
- Test manual SSH connection from container

### Agent Won't Connect
- Check Jenkins logs for connection errors
- Verify `host.docker.internal` resolves correctly
- Ensure jenkins user has correct permissions

### Build Failures
- Check Homebrew installation: `brew doctor`
- Verify environment variables are set
- Check for missing dependencies: `brew list`

## Security Considerations

- The jenkins user has limited privileges
- SSH key authentication is used (not passwords)
- Agent runs in isolated workspace
- Dependencies are managed through Homebrew

## Performance Benefits

- Native ARM64 compilation (no emulation)
- Direct access to Mac-specific APIs
- Faster builds without Docker overhead
- Better integration with macOS development tools
