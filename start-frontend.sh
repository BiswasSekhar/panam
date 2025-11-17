#!/bin/bash

echo "🚀 Starting Panam Frontend..."
cd Frontend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install
fi

echo "🎯 Starting Expo..."
npx expo start
