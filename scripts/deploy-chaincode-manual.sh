#!/bin/bash
set -e

echo "🚀 Manual Chaincode Deployment (Bypassing Docker Build)"
echo ""

# Check Docker version compatibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-docker-version.sh" || true

cd ~/e-waste-tracker/fabric-samples/test-network

export FABRIC_CFG_PATH=~/e-waste-tracker/fabric-samples/config
export PATH=~/e-waste-tracker/fabric-samples/bin:$PATH

# Pre-pull Docker images
echo "📥 Pre-pulling chaincode Docker images..."
docker pull hyperledger/fabric-nodeenv:2.4 2>/dev/null || docker pull hyperledger/fabric-nodeenv:latest

# Prepare chaincode
echo "📦 Preparing chaincode..."
cd ~/e-waste-tracker/chaincode/javascript
rm -rf node_modules package-lock.json
npm install --production

# Package chaincode
echo "📦 Packaging chaincode..."
cd ~/e-waste-tracker/fabric-samples/test-network

peer lifecycle chaincode package ewaste.tar.gz \
    --path ~/e-waste-tracker/chaincode/javascript \
    --lang node \
    --label ewaste_1.0

echo "✅ Chaincode packaged"
echo ""

# Install on Org1
echo "📤 Installing on Org1..."
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example. com/peers/peer0.org1.example.com/tls/ca. crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example. com/users/Admin@org1.example. com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Try installation with timeout and better error handling
for i in {1..3}; do
    echo "Attempt $i/3..."
    if timeout 180 peer lifecycle chaincode install ewaste.tar.gz 2>&1 | tee /tmp/install-org1.log; then
        if grep -q "Chaincode code package identifier" /tmp/install-org1.log; then
            echo "✅ Installed on Org1"
            break
        fi
    fi
    
    # Check for Docker socket errors
    if grep -qi "broken pipe\|docker.sock" /tmp/install-org1.log; then
        echo ""
        echo "❌ Docker socket error detected!"
        echo "This is typically caused by Docker Engine v29+ incompatibility."
        echo "Please check the Docker version warning above and downgrade if needed."
        echo ""
        docker logs peer0.org1.example.com --tail 50 2>/dev/null || true
        exit 1
    fi
    
    if [ $i -eq 3 ]; then
        echo "❌ Installation failed after 3 attempts"
        echo ""
        echo "Checking peer logs:"
        docker logs peer0.org1.example.com --tail 30
        exit 1
    fi
    
    echo "Retrying in 10 seconds..."
    sleep 10
done

echo ""

# Install on Org2
echo "📤 Installing on Org2..."
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca. crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example. com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

timeout 180 peer lifecycle chaincode install ewaste.tar.gz
echo "✅ Installed on Org2"
echo ""

# Get package ID
echo "📋 Getting package ID..."
export CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')
echo "Package ID: $CC_PACKAGE_ID"
echo ""

# Approve for Org1
echo "✅ Approving for Org1..."
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example. com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer. example.com \
    --channelID mychannel \
    --name ewaste \
    --version 1.0 \
    --package-id $CC_PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca-example-com-cert.pem

echo "✅ Org1 approved"
echo ""

# Approve for Org2
echo "✅ Approving for Org2..."
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca. crt
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID mychannel \
    --name ewaste \
    --version 1.0 \
    --package-id $CC_PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example. com/orderers/orderer. example.com/msp/tlscacerts/tlsca-example-com-cert.pem

echo "✅ Org2 approved"
echo ""

# Commit
echo "✅ Committing chaincode definition..."
peer lifecycle chaincode commit -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID mychannel \
    --name ewaste \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca-example-com-cert.pem \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca. crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

echo ""
echo "✅ ============================================"
echo "✅  CHAINCODE DEPLOYED SUCCESSFULLY!"
echo "✅ ============================================"
echo ""
echo "Verify:  peer lifecycle chaincode querycommitted --channelID mychannel --name ewaste"
echo ""
echo "🔗 Next:  cd ~/e-waste-tracker/api && npm start"
