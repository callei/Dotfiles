# Calle's Dotfiles
This is my take on Arch (especially hyprland in CachyOS) ricing, bear in mind, I am not a pro at this lol.

<!-- Screenshots Section -->
<img src="https://github.com/callei/Dotfiles/blob/main/images/screenshot1.png" width="32%"><img src="https://github.com/callei/Dotfiles/blob/main/images/screenshot2.png" width="32%"><img src="https://github.com/callei/Dotfiles/blob/main/images/screenshot3.png" width="32%">

> [!WARNING]
> **Disclaimer:** These dotfiles are tailored for my specific setup and hardware. I cannot guarantee they will work for you.

# Configuration

> [!CAUTION]
> Always backup your existing configurations before applying new ones.

> [!IMPORTANT]
> You need to manually copy these files to your config directory.
> **Crucial:** Files may contain absolute paths (e.g., `/home/calle/...`). You **MUST** search and replace these with your own home directory path before restarting your window manager.

<details>
  <summary>Manual Installation</summary>
  
  1. **Clone the repository:**
     ```fish
     git clone https://github.com/callei/Dotfiles.git ~/Dotfiles
     ```

  2. **Copy configurations:**
     Copy the folders from `.config` to your local `~/.config` directory.
     ```fish
     cp -r ~/Dotfiles/.config/* ~/.config/
     ```
     
  3. **Scripts:**
     Ensure scripts in `~/.config/hypr/scripts` are executable.
     ```fish
     chmod +x ~/.config/hypr/scripts/*
     ```
</details>

## My Applications

<details>
  <summary>🖥️ Hyprland</summary>
  
  ## Overview
  - **Layout**: Dwindle
  - **Gaps**: Inner 5/10, Outer 5/20
  - **Blur**: Enabled for Code, Firefox, Quickshell, Obsidian etc.
  - **Animations**: Bezier curves for smooth window movements.
  
  ## Configuration
  The main configuration file is located at `~/.config/hypr/hyprland.lua`.
</details>

<details>
  <summary>Quickshell</summary>
  
  ## Overview
  A custom layered quickshell application with custom modules.

  ### Bar
  - **Left**: Logo (App launcher), Battery, Clock, Updates + Optional Tailscale widget.
  - **Center**: Workspaces.
  - **Right**: Bluetooth, Network, Memory, Notification daemon, Power menu.
  
  ## Features
  - **Pacman Updates**: Click to run a system update script in a floating terminal, from ml4w updater!.
  - **Network**: Click to open quickshell with fallback to `nmtui`.
  - **Bluetooth**: click to open quickshell menu with option to `blueman-manager`.
  - And much more!
</details>

## Keybinds

### General
`SUPER + Q` - Kill Active Window  
`SUPER + F` - Fullscreen (State 0, toggle)  
`SUPER + M` - Fullscreen (State 1)  
`SUPER + T` - Toggle Floating  
`SUPER + ALT + Arrow Keys` - Switch window position accordingly  

### Applications
`SUPER + RETURN` - Terminal (Kitty)  
`SUPER + E` - File Manager (Nautilus)  
`SUPER + B` - Browser (Firefox)  
`SUPER + C` - Editor (VS Code)  
`SUPER + CTRL + RETURN` - App Launcher (Quickshell)  
`SUPER + L` - Lock Screen (Hyprlock)  
`SUPER + SHIFT + L` - Logout Menu (Wlogout)  

### System
`SUPER + CTRL + B` - Quickshell bluetooth  
`SUPER + CTRL + N` - Quickshell notifications
`SUPER + W` - Wallpaper Selector  
`SUPER + SHIFT + S` - Screenshot (Grim + Slurp)  

> [!TIP]
> More keybinds can be found in `~/.config/hypr/lua/binds.lua`.

## Download Suggestions

Based on the configuration, you will need most of these packages:

```txt
hyprland
quickshell
kitty
fish
fastfetch                   Optional (System Info)
oh-my-posh
hyprlock
hypridle
wlogout
grim
slurp
wl-clipboard
nautilus                    Optional (File Manager)
firefox                     Optional (Browser)
visual-studio-code-bin      Optional (Text Editor)
blueman                     Optional (Bluetooth GUI)
nmtui                       Optional (Network TUI)
pavucontrol                 Optional (Audio Control GUI)
pipewire
wireplumber
playerctl
brightnessctl
gnome-keyring               Easy to use w e.g visual studio
polkit-gnome
ttf-font-awesome
otf-font-awesome
```
## Extra Download Suggestions

Here are some additional tools and fun packages that I recommend for a better terminal:

```txt
helix       A vim alternative, with a good tutorial
btop        Modern resource monitor
bat         Cat clone with syntax highlighting
cava        Console-based Audio Visualizer
cmatrix     Matrix screensaver
cbonsai     Grow a bonsai tree in your terminal :)
```

---
> Old stuff!

<details>
  <summary>🚥 Waybar</summary>
  
  ## Overview
  A top-positioned bar with custom modules.
  
  - **Left**: Logo (App launcher), Battery, Clock, Updates.
  - **Center**: Workspaces.
  - **Right**: Bluetooth, Network, Memory, Notification daemon (SwayNC), Power menu.
  
  ## Features
  - **Pacman Updates**: Click to run a system update script in a floating terminal, from ml4w updater!.
  - **Network**: Click to open `nmtui`.
  - **Bluetooth**: Right-click to open `blueman-manager`.
</details>

<details>
  <summary>🔍 Wofi</summary>
  
  Used as the application launcher.
  - **Trigger**: `SUPER + CTRL + RETURN` or clicking the logo in Waybar.
  - **Style**: Floating with blur enabled.
</details>

<details>
  <summary>🔔 SwayNC & SwayOSD</summary>
  
  - **SwayNC**: Notification Center.
  - **SwayOSD**: On-Screen Display for volume and brightness changes.
</details>

---

## License & Attribution

This project contains code licensed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007.

Parts of the code are based on work from other projects on GitHub. See individual files for details and original sources.

- [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html)

Also, special thanks to Stephan Raabe and the ml4w dotfiles:
https://github.com/mylinuxforwork/dotfiles

And to Eli (also for this readme):
https://github.com/elifouts/Dotfiles

