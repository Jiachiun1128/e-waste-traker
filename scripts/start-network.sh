#!/bin/bash
set -e

echo "🚀 Starting Hyperledger Fabric Network"

# Check Docker version compatibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-docker-version.sh" || true

cd ~/e-waste-tracker/fabric-samples/test-network

export FABRIC_CFG_PATH=~/e-waste-tracker/fabric-samples/config
export PATH=~/e-waste-tracker/fabric-samples/bin:$PATH

# Clean first
echo "🧹 Cleaning previous network..."
./network.sh down

# Start network
echo "🏗️ Starting Fabric network..."
./network.sh up -ca

if [ $? -ne 0 ]; then
    echo "❌ Failed to start network"
    exit 1
fi

# Create channel
echo "📡 Creating channel 'mychannel'..."
./network.sh createChannel -c mychannel

if [ $? -ne 0 ]; then
    echo "❌ Failed to create channel"
    exit 1
fi

echo ""
echo "✅ Network is running!"
echo "✅ Channel 'mychannel' created"
echo ""

# Show running containers
docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "🔗 Next:  Run ./scripts/deploy-chaincode.sh"
