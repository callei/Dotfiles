package files

import (
	"fmt"
	"os"
	"path/filepath"
)

type Paths struct {
	Home                string
	WallpaperDir        string
	ThemeDir            string
	ThemeConf           string
	QuickshellThemeDir  string
	QuickshellThemeConf string
	ThemeCSS            string
	ThemeGTK            string
	KittyTheme          string
	OhMyPoshTheme       string
	WalCacheDir         string
	HyprWallpaperLua    string
	Gtk3Dir             string
	Gtk4Dir             string
}

func NewPaths() (Paths, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return Paths{}, fmt.Errorf("resolve home: %w", err)
	}

	themeDir := filepath.Join(home, ".config", "themes")
	quickshellThemeDir := filepath.Join(home, ".config", "quickshell", "themes")
	return Paths{
		Home:                home,
		WallpaperDir:        filepath.Join(home, "Bilder", "wallpapers"),
		ThemeDir:            themeDir,
		ThemeConf:           filepath.Join(themeDir, "current.conf"),
		QuickshellThemeDir:  quickshellThemeDir,
		QuickshellThemeConf: filepath.Join(quickshellThemeDir, "current.conf"),
		ThemeCSS:            filepath.Join(themeDir, "current.css"),
		ThemeGTK:            filepath.Join(themeDir, "wal-gtk.css"),
		KittyTheme:          filepath.Join(home, ".config", "kitty", "colors-matugen.conf"),
		OhMyPoshTheme:       filepath.Join(home, ".config", "ohmyposh", "mytheme.omp.json"),
		WalCacheDir:         filepath.Join(home, ".cache", "wal"),
		HyprWallpaperLua:    filepath.Join(home, ".config", "hypr", "wallpaper.lua"),
		Gtk3Dir:             filepath.Join(home, ".config", "gtk-3.0"),
		Gtk4Dir:             filepath.Join(home, ".config", "gtk-4.0"),
	}, nil
}

func (p Paths) EnsureDirs() error {
	dirs := []string{
		p.ThemeDir,
		p.QuickshellThemeDir,
		filepath.Dir(p.KittyTheme),
		filepath.Dir(p.OhMyPoshTheme),
		p.WalCacheDir,
		filepath.Dir(p.HyprWallpaperLua),
		p.Gtk3Dir,
		p.Gtk4Dir,
	}
	for _, d := range dirs {
		if err := os.MkdirAll(d, 0o755); err != nil {
			return fmt.Errorf("mkdir %s: %w", d, err)
		}
	}
	return nil
}
