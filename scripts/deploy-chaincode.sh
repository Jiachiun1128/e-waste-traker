#!/bin/bash
set -e

echo "📦 Deploying E-Waste Chaincode"

# Check Docker version compatibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-docker-version.sh" || true

cd ~/e-waste-tracker/fabric-samples/test-network

export FABRIC_CFG_PATH=~/e-waste-tracker/fabric-samples/config
export PATH=~/e-waste-tracker/fabric-samples/bin:$PATH

# Prepare chaincode
echo "📦 Preparing chaincode..."
cd ~/e-waste-tracker/chaincode/javascript

# Clean and reinstall
rm -rf node_modules package-lock.json npm-shrinkwrap.json

# Ensure package.json is correct
cat > package.json <<'EOF'
{
  "name": "ewaste",
  "version": "1.0.0",
  "description": "E-waste chaincode",
  "main": "index.js",
  "scripts": {
    "start": "fabric-chaincode-node start"
  },
  "dependencies":  {
    "fabric-contract-api": "2.2.0",
    "fabric-shim": "2.2.0"
  }
}
EOF

# Install dependencies
npm install --production

cd ~/e-waste-tracker/fabric-samples/test-network

# Fix Docker socket before deployment
echo "🔧 Fixing Docker permissions..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# Try automated deployment
echo "🚀 Deploying chaincode (this may take 3-5 minutes)..."

# Create secure temporary file for logs
DEPLOY_LOG=$(mktemp)
trap "rm -f '$DEPLOY_LOG'" EXIT

# Run deployment with better error handling
if timeout 600 ./network.sh deployCC \
    -ccn ewaste \
    -ccp ~/e-waste-tracker/chaincode/javascript \
    -ccl javascript \
    -ccv 1.0 \
    -ccs 1 2>&1 | tee "$DEPLOY_LOG"; then
    
    # Check if deployment was actually successful
    if grep -q "Chaincode definition committed on channel" "$DEPLOY_LOG"; then
        echo ""
        echo "✅ ============================================"
        echo "✅  CHAINCODE DEPLOYED SUCCESSFULLY!"
        echo "✅ ============================================"
        echo ""
        echo "🔗 Next: Run ./scripts/start-api.sh"
        exit 0
    fi
fi

# Check for specific error patterns
if grep -qi "broken pipe\|docker.sock" "$DEPLOY_LOG" 2>/dev/null; then
    echo ""
    echo "❌ ============================================"
    echo "❌  DOCKER SOCKET ERROR DETECTED"
    echo "❌ ============================================"
    echo ""
    echo "The deployment failed due to Docker communication issues."
    echo "This is typically caused by Docker Engine v29+ incompatibility."
    echo ""
    echo "Please check your Docker version and downgrade if necessary."
    echo "See the warning messages above for instructions."
    echo ""
    echo "You can also try the manual deployment script:"
    echo "  ./scripts/deploy-chaincode-manual.sh"
    echo ""
    exit 1
fi

echo ""
echo "⚠️ Automated deployment failed, trying manual method..."
echo ""

# Manual deployment fallback
echo "📦 Packaging chaincode manually..."
peer lifecycle chaincode package ewaste.tar.gz \
    --path ~/e-waste-tracker/chaincode/javascript \
    --lang node \
    --label ewaste_1.0

# Install on Org1
echo "📤 Installing on Org1..."
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode install ewaste.tar.gz

# Install on Org2
echo "📤 Installing on Org2..."
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode install ewaste.tar.gz

# Get package ID
export CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')
echo "📋 Package ID: $CC_PACKAGE_ID"

# Approve for Org1
echo "✅ Approving for Org1..."
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID mychannel --name ewaste --version 1.0 \
    --package-id $CC_PACKAGE_ID --sequence 1 --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca-example-com-cert.pem

# Approve for Org2
echo "✅ Approving for Org2..."
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID mychannel --name ewaste --version 1.0 \
    --package-id $CC_PACKAGE_ID --sequence 1 --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca-example-com-cert.pem

# Commit
echo "✅ Committing chaincode..."
peer lifecycle chaincode commit -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID mychannel --name ewaste --version 1.0 --sequence 1 --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca-example-com-cert.pem \
    --peerAddresses localhost: 7051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

echo ""
echo "✅ ============================================"
echo "✅  CHAINCODE DEPLOYED SUCCESSFULLY!"
echo "✅ ============================================"
echo ""
echo "🔗 Next: Run ./scripts/start-api.sh"
