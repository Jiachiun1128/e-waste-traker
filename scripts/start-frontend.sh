#!/bin/bash

echo "🚀 Starting E-Waste Frontend"

cd ~/e-waste-tracker/frontend

# Check if dependencies installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo ""
echo "✅ Starting frontend (will open browser automatically)"
echo "✅ Keep this terminal running!"
echo ""

npm start
