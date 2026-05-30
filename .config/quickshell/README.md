# quickshell wallpaper app

This is a Quickshell + Go wallpaper module for Hyprland configs.

## Quick Start

- Start your integrated shell:
  - `quickshell -p ~/.config/quickshell/quickshell/shell.qml`
- Stop:
  - `killall quickshell`
- Optional fish alias for convenience:
  - `alias qs="quickshell -p ~/.config/quickshell/quickshell/shell.qml"`
  - `alias qs-stop="killall quickshell"`

- Stop the integrated shell:
  - `killall quickshell`

We can also add an alias to simplify this later. I should also 
add an exec-once to the config in order to always run this instead of waybar etc. 

## What it updates

- `~/.config/themes/current.conf`
- `~/.config/themes/current.css`
- `~/.config/themes/wal-gtk.css`
- `~/.config/kitty/colors-matugen.conf`
- `~/.config/hypr/wallpaper.lua`
- `~/.cache/wal/{colors,colors.sh,colors.css,wal}` for pywalfox compatibility

If `pywalfox` is installed, `wpctl apply` triggers `pywalfox update` automatically.

The output format is intentionally compatible with existing Waybar/SwayNC/Wlogout/Hyprlock theme usage.

--------------------------------------------------------------

The bar is located in `quickshell/Modules/Bar/Bar.qml`
We also have launcher and wallpaper picker in these modules. 
