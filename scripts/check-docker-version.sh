#!/bin/bash

# Function to check Docker version compatibility
# Hyperledger Fabric has known issues with Docker Engine v29+
# Returns 0 if compatible, 1 if incompatible

echo "🔍 Checking Docker version compatibility..."

# Get Docker version
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null)

if [ -z "$DOCKER_VERSION" ]; then
    echo "❌ ERROR: Cannot detect Docker version. Is Docker running?"
    exit 1
fi

echo "📦 Docker Engine version: $DOCKER_VERSION"

# Extract major version
DOCKER_MAJOR=$(echo "$DOCKER_VERSION" | cut -d. -f1)

# Check if version is 29 or higher
if [ "$DOCKER_MAJOR" -ge 29 ]; then
    echo ""
    echo "⚠️  WARNING: Docker Engine v29+ Detected!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Hyperledger Fabric has a known incompatibility with Docker Engine v29+."
    echo "This causes the error:"
    echo "  'docker build failed: write unix @->/run/docker.sock: write: broken pipe'"
    echo ""
    echo "SOLUTION: Downgrade to Docker Engine v28 or earlier"
    echo ""
    echo "Steps to downgrade on Ubuntu/Debian:"
    echo "  1. Uninstall current Docker:"
    echo "     sudo apt-get remove docker-ce docker-ce-cli containerd.io"
    echo ""
    echo "  2. Install Docker Engine 28:"
    echo "     sudo apt-get update"
    echo "     sudo apt-get install docker-ce=5:28.0.* docker-ce-cli=5:28.0.* containerd.io"
    echo ""
    echo "  3. Verify version:"
    echo "     docker version"
    echo ""
    echo "For other OS, see: https://docs.docker.com/engine/install/"
    echo "Reference: https://github.com/hyperledger/fabric/issues/5350"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Ask user if they want to continue anyway
    read -p "Continue anyway? (not recommended) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled. Please downgrade Docker first."
        exit 1
    fi
    echo "⚠️  Proceeding with incompatible Docker version..."
    echo ""
fi

echo "✅ Docker version is compatible!"
echo ""
