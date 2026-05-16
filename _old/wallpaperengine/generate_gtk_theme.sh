#!/usr/bin/env bash

# Load pywal colors
# We prefer colors.sh for shell sourcing, but we can also parse colors.css if needed.
# Using colors.sh is standard for scripts.
if [[ -f "$HOME/.cache/wal/colors.sh" ]]; then
    source "$HOME/.cache/wal/colors.sh"
else
    echo "Error: pywal colors not found. Run 'wal -i image' first."
    exit 1
fi

THEME_DIR="$HOME/.config/themes"
mkdir -p "$THEME_DIR"

# Output file
GTK_THEME_FILE="$THEME_DIR/wal-gtk.css"

# Generate CSS content
# Mapping pywal colors to GTK named colors
cat > "$GTK_THEME_FILE" << EOF
@define-color accent_color $color1;
@define-color accent_bg_color $color1;
@define-color accent_fg_color $background;

@define-color window_bg_color $background;
@define-color window_fg_color $foreground;

@define-color view_bg_color $background;
@define-color view_fg_color $foreground;

@define-color headerbar_bg_color $background;
@define-color headerbar_fg_color $foreground;
@define-color headerbar_border_color $color1;
@define-color headerbar_backdrop_color @window_bg_color;
@define-color headerbar_shade_color rgba(0, 0, 0, 0.07);

@define-color card_bg_color $color0;
@define-color card_fg_color $foreground;
@define-color card_shade_color rgba(0, 0, 0, 0.07);

@define-color popover_bg_color $background;
@define-color popover_fg_color $foreground;

@define-color dialog_bg_color $background;
@define-color dialog_fg_color $foreground;

/* GTK3 specific mappings (some overlap) */
@define-color theme_fg_color $foreground;
@define-color theme_bg_color $background;
@define-color theme_text_color $foreground;
@define-color theme_base_color $background;
@define-color theme_selected_bg_color $color1;
@define-color theme_selected_fg_color $background;

@define-color borders $color1;
@define-color unfocused_borders $color8;

/* Custom Nautilus/Sidebar tweaks */
window.nautilus-window .sidebar,
window.nautilus-window .sidebar-pane,
window.nautilus-window .navigation-sidebar {
    background-color: $color0;
    color: $foreground;
}

/* Ensure the list inside doesn't override it */
window.nautilus-window .sidebar list,
window.nautilus-window .navigation-sidebar list {
    background-color: transparent;
}

/* Sidebar selected row */
.navigation-sidebar row:selected {
    background-color: $color1;
    color: $background;
}

window.nautilus-window .view {
    background-color: $background;
    color: $foreground;
}

/* Example: Make the path bar look distinct */
.nautilus-window entry.search {
    background-color: $color1;
    color: $background;
}
EOF

# Apply to GTK 3
GTK3_DIR="$HOME/.config/gtk-3.0"
mkdir -p "$GTK3_DIR"
# We link the generated file to gtk.css
# Note: This replaces existing gtk.css. 
ln -sf "$GTK_THEME_FILE" "$GTK3_DIR/gtk.css"
# Also link gtk-dark.css to the same file for consistency
ln -sf "$GTK_THEME_FILE" "$GTK3_DIR/gtk-dark.css"

# Apply to GTK 4
GTK4_DIR="$HOME/.config/gtk-4.0"
mkdir -p "$GTK4_DIR"
ln -sf "$GTK_THEME_FILE" "$GTK4_DIR/gtk.css"
ln -sf "$GTK_THEME_FILE" "$GTK4_DIR/gtk-dark.css"

echo "Generated GTK theme at $GTK_THEME_FILE and linked to GTK config directories."
