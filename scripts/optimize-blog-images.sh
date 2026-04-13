#!/usr/bin/env bash
# Optimize blog images: convert to webp, resize for web, strip metadata
# Requires: cwebp (libwebp), magick (imagemagick)
# Usage: ./scripts/optimize-blog-images.sh [file|directory]

set -euo pipefail

BLOG_DIR="priv/static/images/blog"
MAX_WIDTH=1600
QUALITY=82
WEBP_QUALITY=80

usage() {
    printf "Usage: %s [file|directory]\n" "$0"
    printf "  No args: optimize all non-webp images in %s\n" "$BLOG_DIR"
    printf "  file:    optimize a single image\n"
    printf "  dir:     optimize all images in directory\n"
    exit 1
}

check_deps() {
    for cmd in cwebp magick; do
        if ! command -v "$cmd" &>/dev/null; then
            printf "error: %s not found. Install with: brew install %s\n" "$cmd" \
                "$([ "$cmd" = "cwebp" ] && echo "webp" || echo "imagemagick")"
            exit 1
        fi
    done
}

optimize_image() {
    local src="$1"
    local basename="${src%.*}"
    local ext="${src##*.}"
    local dest="${basename}.webp"

    # Skip if already webp and under 200KB
    if [[ "$ext" == "webp" ]]; then
        local size
        size=$(stat -f%z "$src" 2>/dev/null || stat -c%s "$src" 2>/dev/null)
        if [[ "$size" -lt 204800 ]]; then
            printf "  skip (already optimized): %s (%s)\n" "$(basename "$src")" \
                "$(numfmt --to=iec "$size" 2>/dev/null || echo "${size}B")"
            return
        fi
    fi

    # Get current dimensions
    local width
    width=$(magick identify -format "%w" "$src" 2>/dev/null) || {
        printf "  error: cannot read %s\n" "$(basename "$src")"
        return
    }

    local resize_flag=""
    if [[ "$width" -gt "$MAX_WIDTH" ]]; then
        resize_flag="-resize ${MAX_WIDTH}x"
    fi

    # Convert to webp via magick (handles resize + strip in one pass)
    magick "$src" -strip $resize_flag -quality "$QUALITY" "${basename}_tmp.webp" 2>/dev/null

    # Re-encode with cwebp for better compression
    cwebp -q "$WEBP_QUALITY" -m 6 -quiet "${basename}_tmp.webp" -o "$dest" 2>/dev/null
    rm -f "${basename}_tmp.webp"

    local src_size dest_size
    src_size=$(stat -f%z "$src" 2>/dev/null || stat -c%s "$src" 2>/dev/null)
    dest_size=$(stat -f%z "$dest" 2>/dev/null || stat -c%s "$dest" 2>/dev/null)

    local savings
    if [[ "$src_size" -gt 0 ]]; then
        savings=$(( (src_size - dest_size) * 100 / src_size ))
    else
        savings=0
    fi

    printf "  %s -> %s  (%sKB -> %sKB, -%s%%)\n" \
        "$(basename "$src")" \
        "$(basename "$dest")" \
        "$(( src_size / 1024 ))" \
        "$(( dest_size / 1024 ))" \
        "$savings"

    # Remove original jpg/png if webp was created successfully
    if [[ "$ext" != "webp" && -f "$dest" && "$dest_size" -gt 0 ]]; then
        rm -f "$src"
    fi
}

main() {
    check_deps

    local target="${1:-$BLOG_DIR}"

    if [[ -f "$target" ]]; then
        printf "Optimizing: %s\n" "$target"
        optimize_image "$target"
    elif [[ -d "$target" ]]; then
        printf "Optimizing images in: %s\n" "$target"
        printf "  max width: %spx, webp quality: %s\n\n" "$MAX_WIDTH" "$WEBP_QUALITY"

        local count=0
        while IFS= read -r -d '' file; do
            optimize_image "$file"
            (( count++ )) || true
        done < <(find "$target" -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -print0 | sort -z)

        if [[ "$count" -eq 0 ]]; then
            printf "  No jpg/jpeg/png files found to optimize.\n"
        else
            printf "\n  Optimized %d images.\n" "$count"
        fi
    else
        printf "error: %s not found\n" "$target"
        exit 1
    fi
}

main "$@"
