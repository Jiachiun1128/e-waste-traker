#!/bin/bash
set -e

echo "🚀 E-WASTE TRACKER - FULL DEPLOYMENT"
echo "===================================="
echo ""

# Step 1: Cleanup
echo "STEP 1/3: Cleanup"
~/e-waste-tracker/scripts/cleanup.sh

echo ""
echo "STEP 2/3: Start Network"
~/e-waste-tracker/scripts/start-network.sh

echo ""
echo "STEP 3/3: Deploy Chaincode"
~/e-waste-tracker/scripts/deploy-chaincode.sh

echo ""
echo "✅ ============================================"
echo "✅  DEPLOYMENT COMPLETE!"
echo "✅ ============================================"
echo ""
echo "📋 To start the application:"
echo ""
echo "Terminal 1: ~/e-waste-tracker/scripts/start-api.sh"
echo "Terminal 2: ~/e-waste-tracker/scripts/start-frontend.sh"
echo ""
