#!/bin/bash

echo "🧹 Cleaning E-Waste Tracker Environment"

# Stop network
cd ~/e-waste-tracker/fabric-samples/test-network
./network.sh down 2>/dev/null || true

# Stop all containers
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Clean networks
docker network prune -f

# Clean volumes
docker volume prune -f

# Remove chaincode artifacts
rm -rf ~/e-waste-tracker/fabric-samples/test-network/channel-artifacts
rm -rf ~/e-waste-tracker/fabric-samples/test-network/system-genesis-block
rm -rf ~/e-waste-tracker/fabric-samples/test-network/organizations
rm -f ~/e-waste-tracker/fabric-samples/test-network/*.tar.gz

# Clean API wallet
rm -rf ~/e-waste-tracker/api/wallet

echo "✅ Cleanup complete!"
