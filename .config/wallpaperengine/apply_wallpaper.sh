#!/usr/bin/env bash

WP="$1"
NAME=$(basename "$WP" | sed 's/\.[^.]*$//')

THEME_DIR="$HOME/.config/themes"

mkdir -p "$THEME_DIR"

# start daemon if not running
pgrep swww-daemon > /dev/null || swww-daemon &

# apply wallpaper using wipe transition
swww img "$WP" --transition-type grow --transition-step 90 --transition-pos top

# generate pywal theme (colors)
wal -n -q -i "$WP"

# Generate existing theme (user's script)
if [[ -x "$HOME/.config/wallpaperengine/generate_theme.sh" ]]; then
    "$HOME/.config/wallpaperengine/generate_theme.sh" "$NAME"
fi

# Generate GTK3/4 themes
if [[ -x "$HOME/.config/wallpaperengine/generate_gtk_theme.sh" ]]; then
    "$HOME/.config/wallpaperengine/generate_gtk_theme.sh"
fi

# Reload GTK themes
if [[ -x "$HOME/.config/wallpaperengine/gtk_reload.py" ]]; then
    "$HOME/.config/wallpaperengine/gtk_reload.py"
fi

# update autostart wallpaper
AUTOSTART="$HOME/.config/hypr/wallpaper.conf"
echo "exec-once = swww-daemon" > "$AUTOSTART"
echo "exec-once = swww img \"$WP\" --transition-type grow" >> "$AUTOSTART"

# ------------------------------------------------ #

# reload hyprland theme
pkill swayosd-server
swayosd-server &


# Fully restart swaync after theme change
pkill swaync
(sleep 0.5; swaync &) &

pywalfox update &>/dev/null

hyprctl reload &>/dev/null

# Reload Kitty config if running
if pgrep -x "kitty" > /dev/null; then
    kill -SIGUSR1 $(pgrep -x "kitty")
fi