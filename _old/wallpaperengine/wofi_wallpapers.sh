#!/usr/bin/env bash

# ----------- Wallpaper Selector Script ----------- #
# Configuration
WALLPAPER_DIR="$HOME/Bilder/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-selector"  # Cache directory for thumbnails
THUMBNAIL_WIDTH="250"  # Thumbnail width in pixels (16:9)
THUMBNAIL_HEIGHT="141"  # Thumbnail height

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to generate a thumbnail
generate_thumbnail() {
    local input="$1"
    local output="$2"
    magick "$input" -thumbnail "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}^" -gravity center -extent "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" "$output"
}

# Function to generate the menu
generate_menu() {
    # Add all wallpapers in the directory
    for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png}; do
        # Skip if no images found
        [[ -f "$img" ]] || continue
        # Generate thumbnail filename
        thumbnail="$CACHE_DIR/$(basename "${img%.*}").png"
        # Generate thumbnail if it doesn't exist or is older than the source image
        if [[ ! -f "$thumbnail" ]] || [[ "$img" -nt "$thumbnail" ]]; then
            generate_thumbnail "$img" "$thumbnail"
        fi
        # Print menu option (filename and path)
        echo -en "img:$thumbnail\x00info:$(basename "$img")\x1f$img\n"
    done
}

# Use wofi to show the menu with wallpapers
CHOICE=$(generate_menu | wofi --show dmenu -n \
    --cache-file /dev/null \
    --define "image-size=${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" \
    --columns 3 \
    --allow-images \
    --insensitive \
    --sort-order=default \
    --prompt "Select Wallpaper" \
    --conf ~/.config/wofi/wallpaper \
)

# If nothing was selected, exit script
if [[ -z "$CHOICE" ]]; then
    exit
fi

# Extract filename from selection
# CHOICE is truncated at the null byte, so we only get the thumbnail path.
# Reconstruct the original path from the thumbnail filename.
CLEAN_CHOICE=$(echo "$CHOICE" | sed 's/^img://')
BASENAME=$(basename "$CLEAN_CHOICE" .png)

# Find the original file in WALLPAPER_DIR
SELECTED_IMG=""
for ext in jpg jpeg png; do
    if [[ -f "$WALLPAPER_DIR/$BASENAME.$ext" ]]; then
        SELECTED_IMG="$WALLPAPER_DIR/$BASENAME.$ext"
        break
    fi
done

if [[ -z "$SELECTED_IMG" ]]; then
    # Fallback if not found
    SELECTED_IMG="${CHOICE##*$'\x1f'}"
fi

# Run apply_wallpaper.sh with the selected image
"$HOME/.config/wallpaperengine/apply_wallpaper.sh" "$SELECTED_IMG"