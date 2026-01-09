#!/bin/bash

echo "🚀 Starting E-Waste API Server"

cd ~/e-waste-tracker/api

# Check if dependencies installed
if [ !  -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Clean wallet
rm -rf wallet

echo ""
echo "✅ Starting API on http://localhost:3000"
echo "✅ Keep this terminal running!"
echo ""

npm start
