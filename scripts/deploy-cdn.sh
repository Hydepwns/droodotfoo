#!/usr/bin/env bash
# Deploy static assets to Cloudflare Pages CDN
# The Phoenix app continues running on Fly.io and references CDN for static assets
# Usage: ./scripts/deploy-cdn.sh

set -e

echo "=== Deploying Static Assets to Cloudflare CDN ==="
echo ""

# Build minified assets
echo "[1/2] Building and digesting static assets..."
mix assets.deploy

echo ""
echo "[2/2] Deploying to Cloudflare Pages..."

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "Error: Wrangler CLI not found!"
    echo ""
    echo "Install it with: npm install -g wrangler"
    echo "Then login with: wrangler login"
    exit 1
fi

# Deploy using wrangler
wrangler pages deploy priv/static --project-name=droodotfoo-assets

echo ""
echo "=== CDN Deployment Complete! ==="
echo ""
echo "Next steps to enable CDN on your Fly.io deployment:"
echo ""
echo "1. Get your Cloudflare Pages URL (shown above, e.g., droodotfoo-assets.pages.dev)"
echo ""
echo "2. Configure Fly.io to use the CDN:"
echo "   fly secrets set CDN_HOST=<your-project>.pages.dev"
echo ""
echo "3. Redeploy your Phoenix app on Fly.io (already configured to use CDN):"
echo "   fly deploy"
echo ""
echo "Your Phoenix app on Fly.io will now serve static assets from Cloudflare CDN."
