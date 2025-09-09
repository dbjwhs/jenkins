#!/bin/bash
# MIT License
# Copyright (c) 2025 dbjwhs

set -e

echo "🔧 Jenkins Plugin Update (Rebuild Method)"
echo "========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if plugins.txt exists
if [ ! -f "plugins.txt" ]; then
    print_color $RED "❌ plugins.txt not found"
    exit 1
fi

print_color $BLUE "📋 Current plugins in plugins.txt:"
cat plugins.txt | sed 's/^/   • /'

echo ""
read -p "Update all plugins to latest versions? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_color $YELLOW "📋 Update cancelled"
    exit 0
fi

# Create backup
print_color $BLUE "💾 Creating backup..."
BACKUP_DIR="plugin-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current Docker volume if Jenkins is running
if docker-compose ps | grep -q "jenkins.*Up"; then
    print_color $BLUE "📦 Backing up Jenkins data..."
    if docker run --rm -v jenkins_home:/source -v jenkins_backup:/backup alpine:latest tar czf /backup/jenkins-plugins-backup.tar.gz -C /source . 2>/dev/null; then
        print_color $GREEN "✅ Backup created in volume: jenkins_backup"
    else
        print_color $YELLOW "⚠️  Could not create Docker volume backup"
    fi
fi

# Copy current plugins.txt as backup
cp plugins.txt "$BACKUP_DIR/plugins.txt.backup"
print_color $GREEN "✅ plugins.txt backed up to $BACKUP_DIR/"

# Stop Jenkins
print_color $BLUE "⏸️  Stopping Jenkins..."
docker-compose down

# Rebuild with fresh plugins (using latest versions)
print_color $BLUE "🔨 Rebuilding Jenkins with latest plugin versions..."
print_color $YELLOW "   This will install the latest version of all plugins in plugins.txt"

# Build with no cache to ensure fresh plugin downloads
docker-compose build --no-cache

# Start Jenkins
print_color $BLUE "🚀 Starting Jenkins with updated plugins..."
docker-compose up -d

# Wait for Jenkins to start
print_color $BLUE "⏳ Waiting for Jenkins to initialize with new plugins..."
sleep 45

# Health check
RETRY_COUNT=0
MAX_RETRIES=12

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s http://localhost:8080/login > /dev/null 2>&1; then
        print_color $GREEN "✅ Jenkins is healthy!"
        
        # Show Jenkins version and plugin count
        VERSION=$(curl -s http://localhost:8080/api/json 2>/dev/null | jq -r '.version // "unknown"' 2>/dev/null || echo "unknown")
        PLUGIN_COUNT=$(curl -s -u dbjwhs:jenkins "http://localhost:8080/pluginManager/api/json?depth=1" 2>/dev/null | jq -r '.plugins | length' 2>/dev/null || echo "unknown")
        
        print_color $GREEN "🎉 Jenkins updated successfully!"
        echo "   • Jenkins version: $VERSION"
        echo "   • Installed plugins: $PLUGIN_COUNT"
        echo "   • URL: http://localhost:8080"
        
        print_color $BLUE "🔒 Security Note:"
        print_color $GREEN "   ✅ All plugins updated to latest versions"
        print_color $GREEN "   ✅ Git client plugin vulnerability should be resolved"
        
        print_color $YELLOW "💡 Next steps:"
        echo "   1. Login to Jenkins and verify all jobs work correctly"
        echo "   2. Check that no security warnings remain in Jenkins UI"
        echo "   3. If issues occur, you can restore from backup in $BACKUP_DIR/"
        
        exit 0
    fi
    
    echo "⏳ Jenkins not ready yet, retrying in 10 seconds... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT+1))
done

print_color $RED "❌ Jenkins failed to start properly after plugin update"
print_color $YELLOW "🔄 To rollback:"
echo "   1. docker-compose down"
echo "   2. cp $BACKUP_DIR/plugins.txt.backup plugins.txt"
echo "   3. docker-compose build --no-cache"
echo "   4. docker-compose up -d"

exit 1
