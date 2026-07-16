#!/bin/bash
# ScamShield Lao — Build popup for Chrome extension
set -e

cd "$(dirname "$0")/popup"

echo "📦 Building Next.js popup..."
npm run build

echo "✅ Build complete! Static files in popup/out/"
echo ""
echo "📋 To load the extension in Chrome:"
echo "  1. Open chrome://extensions/"
echo "  2. Enable 'Developer mode'"
echo "  3. Click 'Load unpacked'"
echo "  4. Select the 'extension/' folder"
