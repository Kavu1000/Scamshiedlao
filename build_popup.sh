#!/bin/bash
# ScamShield Lao — Build the Next.js design playground (popup/)
#
# NOTE: This does NOT build the extension popup. The extension loads the
# hand-authored vanilla popup at extension/popup/ (index.html + popup.css +
# popup.js). Do NOT copy popup/out/ over extension/popup/ — Next.js static
# export can't run inside the MV3 extension (inline scripts are CSP-blocked,
# and /_next/ asset paths 404 from the popup/ subdirectory).
#
# This script is only for previewing the design in a normal browser.
set -e

cd "$(dirname "$0")/popup"

echo "📦 Building Next.js design preview (popup/)..."
npm run build

echo "✅ Build complete — static files in popup/out/ (browser preview only)."
echo "ℹ️  The extension popup is extension/popup/ (edit those files directly)."
