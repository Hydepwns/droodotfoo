#!/bin/bash

# Bundle Analysis Script for droo.foo
# Analyzes JavaScript bundle size and provides optimization recommendations

echo "[ANALYZING] Analyzing droo.foo Bundle Size..."
echo "=============================================="

# Build assets in production mode
echo "Building production assets..."
MIX_ENV=prod mix assets.deploy

# Check if metafile was generated
if [ ! -f "priv/static/assets/js/meta.json" ]; then
    echo "[X] Meta file not found. Running esbuild with metafile generation..."
    cd assets && npx esbuild js/app.js \
        --bundle \
        --target=es2022 \
        --outdir=../priv/static/assets/js \
        --minify \
        --tree-shaking=true \
        --metafile=../priv/static/assets/js/meta.json \
        --analyze
    cd ..
fi

# Analyze bundle sizes
echo ""
echo "[REPORT] Bundle Size Report:"
echo "----------------------------"

# Get main bundle size
if [ -f "priv/static/assets/js/app.js" ]; then
    MAIN_SIZE=$(du -h priv/static/assets/js/app.js | cut -f1)
    MAIN_SIZE_BYTES=$(stat -f%z priv/static/assets/js/app.js 2>/dev/null || stat -c%s priv/static/assets/js/app.js 2>/dev/null)
    echo "Main Bundle: $MAIN_SIZE"

    # Check if gzip is available
    if command -v gzip &> /dev/null; then
        GZIP_SIZE=$(gzip -c priv/static/assets/js/app.js | wc -c)
        GZIP_SIZE_KB=$((GZIP_SIZE / 1024))
        echo "Gzipped: ${GZIP_SIZE_KB}KB"
    fi
fi

# Check for chunk files
CHUNKS=$(find priv/static/assets/js/chunks -name "*.js" 2>/dev/null | wc -l)
if [ "$CHUNKS" -gt 0 ]; then
    echo "Code Chunks: $CHUNKS files"
    TOTAL_CHUNK_SIZE=$(du -sh priv/static/assets/js/chunks 2>/dev/null | cut -f1)
    echo "Total Chunks Size: $TOTAL_CHUNK_SIZE"
fi

# CSS bundle size
if [ -f "priv/static/assets/css/app.css" ]; then
    CSS_SIZE=$(du -h priv/static/assets/css/app.css | cut -f1)
    echo "CSS Bundle: $CSS_SIZE"
fi

# Total assets size
TOTAL_SIZE=$(du -sh priv/static/assets | cut -f1)
echo "Total Assets: $TOTAL_SIZE"

echo ""
echo "[RECOMMENDATIONS] Optimization Recommendations:"
echo "-----------------------------------------------"

# Check main bundle size and provide recommendations
if [ -n "$MAIN_SIZE_BYTES" ]; then
    if [ "$MAIN_SIZE_BYTES" -gt 500000 ]; then
        echo "[WARNING] Main bundle is larger than 500KB"
        echo "   Consider:"
        echo "   - Implementing more code splitting"
        echo "   - Removing unused dependencies"
        echo "   - Using dynamic imports for large features"
    elif [ "$MAIN_SIZE_BYTES" -gt 250000 ]; then
        echo "[INFO] Main bundle is moderately sized (250-500KB)"
        echo "   Consider:"
        echo "   - Lazy loading non-critical features"
        echo "   - Tree shaking unused exports"
    else
        echo "[OK] Main bundle is well optimized (<250KB)"
    fi
fi

# Check for common issues
echo ""
echo "[CHECKING] Checking for common issues..."

# Check for source maps in production
if ls priv/static/assets/js/*.map 1> /dev/null 2>&1; then
    echo "[WARNING] Source maps found in production build"
    echo "   Remove source maps for production deployment"
fi

# Check for console statements
if grep -q "console\." priv/static/assets/js/app.js 2>/dev/null; then
    echo "[WARNING] Console statements found in production bundle"
    echo "   Add --drop:console to build config"
fi

# Generate detailed report with esbuild
if [ -f "priv/static/assets/js/meta.json" ]; then
    echo ""
    echo "[ANALYSIS] Detailed Bundle Analysis:"
    echo "------------------------------------"
    # Use node to analyze the metafile
    node -e "
      const fs = require('fs');
      const meta = JSON.parse(fs.readFileSync('priv/static/assets/js/meta.json'));
      const outputs = Object.entries(meta.outputs);
      console.log('Top Dependencies by Size:');
      const inputs = Object.entries(meta.inputs)
        .sort((a, b) => b[1].bytes - a[1].bytes)
        .slice(0, 10);
      inputs.forEach(([path, data]) => {
        const size = (data.bytes / 1024).toFixed(1);
        const name = path.split('/').pop();
        console.log(\`  \${name.padEnd(40)} \${size}KB\`);
      });
    " 2>/dev/null || echo "Install esbuild for detailed analysis"
fi

# Performance budget check
echo ""
echo "[BUDGET] Performance Budget Check:"
echo "----------------------------------"
BUDGET_JS=300000  # 300KB
BUDGET_CSS=50000  # 50KB

if [ -n "$MAIN_SIZE_BYTES" ] && [ "$MAIN_SIZE_BYTES" -gt "$BUDGET_JS" ]; then
    OVER=$((MAIN_SIZE_BYTES - BUDGET_JS))
    OVER_KB=$((OVER / 1024))
    echo "[FAIL] JS budget exceeded by ${OVER_KB}KB"
else
    echo "[OK] JS within budget (<300KB)"
fi

# Provide optimization script
echo ""
echo "[TIP] Quick Optimizations:"
echo "--------------------------"
echo "1. Run: mix phx.digest.clean --all"
echo "2. Run: MIX_ENV=prod mix assets.deploy"
echo "3. Enable gzip compression in your web server"
echo "4. Use CDN for static assets"
echo "5. Implement Service Worker for caching"

echo ""
echo "[COMPLETE] Analysis complete!"