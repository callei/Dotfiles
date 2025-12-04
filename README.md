# Calle's Dotfiles
This is my take on Arch (especially in CachyOS) ricing, bear in mind, I am not a pro at this lol.

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
     Ensure scripts in `~/.config/hypr/scripts` and `~/.config/waybar/scripts` are executable.
     ```fish
     chmod +x ~/.config/hypr/scripts/*
     chmod +x ~/.config/waybar/scripts/*
     ```
</details>

## My Applications

<details>
  <summary>🖥️ Hyprland</summary>
  
  ## Overview
  - **Layout**: Dwindle
  - **Gaps**: Inner 5/10, Outer 5/20
  - **Blur**: Enabled for Code, Firefox, Waybar, Wofi, SwayNC, SwayOSD.
  - **Animations**: Custom bezier curves for smooth window movements.
  
  ## Configuration
  The main configuration file is located at `~/.config/hypr/hyprland.conf`.
</details>

<details>
  <summary>🚥 Waybar</summary>
  
  ## Overview
  A top-positioned bar with custom modules.
  
  - **Left**: Logo, Battery, Clock, Pacman Updates.
  - **Center**: Workspaces.
  - **Right**: Bluetooth, Network, Memory, Notifications, Power.
  
  ## Features
  - **Pacman Updates**: Click to run a system update script in a floating terminal.
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

<details>
  <summary>🐚 Fish & Oh My Posh</summary>
  
  - **Shell**: Fish
  - **Prompt**: Oh My Posh (configured in `.config/ohmyposh`)
  - **Terminal**: Kitty
</details>

<details>
  <summary>🎨 Wallpaper Engine</summary>
  
  Custom scripts located in `.config/wallpaperengine` for managing wallpapers and generating themes.
  - `wofi_wallpapers.sh`: Select wallpapers using Wofi.
  - `generate_theme.sh`: Likely used for dynamic theming.
</details>

## Keybinds

### General
`SUPER + Q` - Kill Active Window  
`SUPER + F` - Fullscreen (State 0)  
`SUPER + M` - Fullscreen (State 1)  
`SUPER + T` - Toggle Floating  
`SUPER + J` - Toggle Split  
`SUPER + K` - Swap Split  

### Applications
`SUPER + RETURN` - Terminal (Kitty)  
`SUPER + E` - File Manager (Nautilus)  
`SUPER + B` - Browser (Firefox)  
`SUPER + C` - Editor (VS Code)  
`SUPER + CTRL + RETURN` - App Launcher (Wofi)  
`SUPER + L` - Lock Screen (Hyprlock)  
`SUPER + SHIFT + L` - Logout Menu (Wlogout)  

### System
`SUPER + CTRL + B` - Reload Waybar  
`SUPER + CTRL + N` - Reload SwayNC  
`SUPER + W` - Wallpaper Selector  
`SUPER + SHIFT + S` - Screenshot (Grim + Slurp)  

> [!TIP]
> More keybinds can be found in `~/.config/hypr/hyprland.conf`.

## Download Suggestions

Based on the configuration, you will need most of these packages:

```txt
hyprland
waybar
wofi
kitty
fish
fastfetch                   Optional (System Info)
oh-my-posh
swaync
swayosd-git
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

Here are some additional tools and fun packages that I recommend for a better terminal experience:

```txt
btop        Modern resource monitor
bat         Cat clone with syntax highlighting
cava        Console-based Audio Visualizer
cmatrix     Matrix screensaver
cbonsai     Grow a bonsai tree in your terminal :)
```

## License & Attribution

This project contains code licensed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007.

Parts of the code are based on work from other projects on GitHub. See individual files for details and original sources.

- [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html)

Also, special thanks to Stephan Raabe and the ml4w dotfiles:
https://github.com/mylinuxforwork/dotfiles

And to Eli (also for this readme):
https://github.com/elifouts/Dotfiles

