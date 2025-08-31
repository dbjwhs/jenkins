# Environment Configuration Setup

This document explains how to configure the `.env` file for the Jenkins CI/CD system.

## Required Environment Variables

The Jenkins setup requires the following environment variables to be configured in a `.env` file:

### 1. MAC_MINI_SSH_KEY
SSH private key for connecting to the Mac mini M2 agent.

```bash
MAC_MINI_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAFwAAAAdzc2gtcn...
[your full SSH private key content here]
-----END OPENSSH PRIVATE KEY-----"
```

### 2. ANTHROPIC_API_KEY
API key for Claude integration in C++ projects.

```bash
ANTHROPIC_API_KEY="sk-ant-api03-your-anthropic-key-here"
```

## Setting Up the .env File on Remote System

### On the Mac mini M2 (Remote Jenkins Server):

1. **Navigate to the Jenkins directory:**
   ```bash
   cd /path/to/jenkins
   ```

2. **Create the .env file:**
   ```bash
   touch .env
   chmod 600 .env  # Restrict permissions for security
   ```

3. **Edit the .env file:**
   ```bash
   nano .env
   ```

4. **Add the environment variables:**
   ```bash
   # SSH key for Mac mini agent connection
   MAC_MINI_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
   [paste your SSH private key here - keep the quotes and newlines intact]
   -----END OPENSSH PRIVATE KEY-----"

   # Anthropic API key for Claude integration
   ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"
   ```

5. **Verify the file:**
   ```bash
   ls -la .env
   cat .env  # Check content (be careful with sensitive data)
   ```

## Security Considerations

- **Never commit the `.env` file to git** - it's already in `.gitignore`
- **Restrict file permissions:** `chmod 600 .env`
- **Use environment-specific keys** for different environments
- **Regularly rotate API keys** for security
- **Keep backups** of working configurations in a secure location

## Usage in Jenkins

### SSH Key Usage
The `MAC_MINI_SSH_KEY` is automatically used by Jenkins Configuration as Code (JCasC) to establish SSH connections to the Mac mini agent.

### Anthropic API Key Usage
The `ANTHROPIC_API_KEY` is used in the CQL pipeline for live API integration tests:

- **Main branch builds:** Full integration tests with live API calls
- **Other branches:** Tests run without live API integration

## Troubleshooting

### SSH Connection Issues
```bash
# Check if SSH key is valid
ssh-keygen -l -f ~/.ssh/jenkins_agent_key
```

### API Key Issues
```bash
# Test API key (if you have curl available)
curl -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
     -H "Content-Type: application/json" \
     https://api.anthropic.com/v1/messages
```

### Jenkins Container Issues
```bash
# Restart Jenkins to pick up new environment variables
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs -f jenkins
```

## Example .env File Template

```bash
# ===========================================
# Jenkins Environment Configuration
# ===========================================
# 
# SECURITY WARNING: Never commit this file!
# Keep permissions restricted: chmod 600 .env
#

# SSH Key for Mac mini M2 agent connection
# Generate with: ssh-keygen -t ed25519 -f ~/.ssh/jenkins_agent_key
MAC_MINI_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
[PASTE YOUR SSH PRIVATE KEY HERE]
-----END OPENSSH PRIVATE KEY-----"

# Anthropic API Key for Claude integration
# Get from: https://console.anthropic.com/
ANTHROPIC_API_KEY="sk-ant-api03-[YOUR-KEY-HERE]"

# Optional: Additional environment variables can be added here
# GITHUB_TOKEN="ghp_your_github_token_here"
# SLACK_WEBHOOK="https://hooks.slack.com/services/..."
```

## Updating Remote System

After making changes to the Jenkins configuration:

1. **Pull latest changes:**
   ```bash
   git pull origin main
   ```

2. **Update .env file if needed:**
   ```bash
   nano .env
   ```

3. **Restart Jenkins:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

4. **Verify changes:**
   ```bash
   docker-compose logs -f jenkins
   ```
