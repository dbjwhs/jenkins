#!/bin/bash
# MIT License
# Copyright (c) 2025 dbjwhs

set -e

echo "🚀 Jenkins LTS Update Script"
echo "============================"

# Unlock macOS keychain for Docker operations (required on macOS for Docker authentication)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔑 Unlocking macOS keychain for Docker operations..."
    if security -v unlock-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null; then
        echo "✅ Keychain unlocked successfully"
    else
        echo "⚠️  Could not unlock keychain automatically"
        echo "💡 Please run: security -v unlock-keychain ~/Library/Keychains/login.keychain-db"
        echo "📋 Then rerun this script"
        exit 1
    fi
fi

# Get latest LTS version
echo "📡 Fetching latest Jenkins LTS version..."
LATEST_LTS=$(curl -sL https://updates.jenkins.io/stable/latestCore.txt | tr -d '\n\r')

if [ -z "$LATEST_LTS" ]; then
    echo "❌ Failed to fetch latest LTS version"
    exit 1
fi

# Validate version format (should be like 2.516.2)
if ! echo "$LATEST_LTS" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "❌ Invalid version format received: $LATEST_LTS"
    exit 1
fi

echo "📦 Latest LTS version: $LATEST_LTS"

# Get current version from Dockerfile
CURRENT_VERSION=$(grep 'FROM jenkins/jenkins:' Dockerfile | cut -d':' -f3 | tr -d '\n\r' | sed 's/[[:space:]]*$//')
echo "📋 Current version in Dockerfile: ${CURRENT_VERSION:-lts}"

# If using 'lts' tag, we should update to specific version for better control
if [ "$CURRENT_VERSION" = "lts" ]; then
    echo "📌 Currently using 'lts' tag - will pin to specific version: $LATEST_LTS"
elif [ "$CURRENT_VERSION" = "$LATEST_LTS" ]; then
    echo "✅ Already running latest LTS version: $LATEST_LTS"
    exit 0
fi

# Backup current setup
echo "💾 Creating backup..."
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup .env file if it exists (critical for Mac mini agent)
if [ -f ".env" ]; then
    echo "🔑 Backing up .env file..."
    cp .env "$BACKUP_DIR/.env.backup"
    echo "✅ .env backed up to $BACKUP_DIR/.env.backup"
else
    echo "⚠️  No .env file found - Mac mini agent will not work after update"
    echo "💡 You'll need to recreate .env with MAC_MINI_SSH_KEY after update"
fi

# Check if Jenkins is running before attempting backup
if docker-compose ps | grep -q "jenkins.*Up"; then
    echo "⏸️  Stopping Jenkins for backup..."
    docker-compose down
fi

# Try to create backup, but don't fail if Docker auth issues
echo "📦 Attempting to backup Jenkins data..."
if docker volume ls | grep -q "jenkins_home"; then
    # Create backup volume if it doesn't exist
    docker volume create jenkins_backup 2>/dev/null || true
    
    # Try to backup, but continue if it fails (e.g., due to keychain issues)
    if docker run --rm -v jenkins_home:/source -v jenkins_backup:/backup alpine:latest tar czf /backup/jenkins-backup.tar.gz -C /source . 2>/dev/null; then
        echo "✅ Backup created in volume: jenkins_backup"
    else
        echo "⚠️  Could not create Docker volume backup (keychain/auth issue)"
        echo "💡 Tip: Run 'security -v unlock-keychain ~/Library/Keychains/login.keychain-db' if on macOS"
        echo "📝 Continuing without backup - Dockerfile.bak will be available for rollback"
    fi
else
    echo "ℹ️  No existing Jenkins volume found, skipping backup"
fi

# Update Dockerfile
echo "📝 Updating Dockerfile to version $LATEST_LTS..."
sed -i.bak "s/FROM jenkins\/jenkins:.*/FROM jenkins\/jenkins:$LATEST_LTS/" Dockerfile

# Rebuild and restart
echo "🔨 Rebuilding Docker image..."
docker-compose build --no-cache

echo "🚀 Starting Jenkins with new version..."
docker-compose up -d

echo "⏳ Waiting for Jenkins to start..."
sleep 30

# Health check
echo "🔍 Performing health check..."
RETRY_COUNT=0
MAX_RETRIES=12

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s http://localhost:8080/login > /dev/null; then
        echo "✅ Jenkins is healthy!"
        NEW_VERSION=$(curl -s http://localhost:8080/api/json 2>/dev/null | jq -r '.version // "unknown"' 2>/dev/null || echo "$LATEST_LTS")
        echo "🎉 Successfully updated to Jenkins version: $NEW_VERSION"
        
        # Restore .env file if it was backed up
        if [ -f "$BACKUP_DIR/.env.backup" ]; then
            echo "🔑 Restoring .env file..."
            cp "$BACKUP_DIR/.env.backup" .env
            echo "✅ .env file restored"
        fi
        
        # Cleanup backup files
        rm -f Dockerfile.bak
        echo "🧹 Cleanup completed"
        
        echo ""
        echo "🎯 Update Summary:"
        echo "  Previous: ${CURRENT_VERSION:-lts}"
        echo "  Current:  $NEW_VERSION"
        echo "  URL:      http://localhost:8080"
        echo ""
        echo "💡 If you encounter issues, restore from backup:"
        echo "  docker volume rm jenkins_home"
        echo "  docker volume create jenkins_home"
        echo "  docker run --rm -v jenkins_backup:/backup -v jenkins_home:/restore alpine tar xzf /backup/jenkins-backup.tar.gz -C /restore"
        exit 0
    fi
    
    echo "⏳ Jenkins not ready yet, retrying in 10 seconds... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT+1))
done

echo "❌ Jenkins failed to start properly after update"
echo "🔄 Rolling back to previous version..."

# Rollback
mv Dockerfile.bak Dockerfile
docker-compose build --no-cache
docker-compose up -d

echo "⚠️  Rollback completed. Please check the logs and try again."
exit 1
