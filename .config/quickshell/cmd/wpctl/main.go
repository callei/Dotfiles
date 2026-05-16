package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"quickshell/internal/apps"
	"quickshell/internal/colors"
	"quickshell/internal/files"
	"quickshell/internal/firefox"
	"quickshell/internal/system"
	"quickshell/internal/theme"
	"quickshell/internal/wallpaper"
)

type stateOut struct {
	Wallpaper string `json:"wallpaper"`
	ThemeConf string `json:"themeConf"`
	ThemeCSS  string `json:"themeCss"`
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}

	paths, err := files.NewPaths()
	if err != nil {
		die(err)
	}
	if err := paths.EnsureDirs(); err != nil {
		die(err)
	}

	switch os.Args[1] {
	case "list":
		handleList(paths)
	case "current":
		handleCurrent(paths)
	case "apply":
		handleApply(paths)
	case "apps":
		handleApps(paths)
	case "launch":
		handleLaunch(paths)
	default:
		usage()
		os.Exit(1)
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: wpctl [list|current|apply <image>|apps|launch <desktop-id>] [--json] [--refresh]")
}

func handleList(paths files.Paths) {
	items, err := wallpaper.List(paths.WallpaperDir)
	if err != nil {
		die(err)
	}
	if hasFlag("--json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		_ = enc.Encode(items)
		return
	}
	for _, item := range items {
		fmt.Println(item.Path)
	}
}

func handleCurrent(paths files.Paths) {
	wallpaperPath := ""
	if b, err := os.ReadFile(paths.ThemeConf); err == nil {
		lines := splitLines(string(b))
		for _, line := range lines {
			if len(line) > 13 && line[:13] == "$wallpaper = " {
				wallpaperPath = line[13:]
				break
			}
		}
	}

	state := stateOut{
		Wallpaper: wallpaperPath,
		ThemeConf: paths.ThemeConf,
		ThemeCSS:  paths.ThemeCSS,
	}
	if hasFlag("--json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		_ = enc.Encode(state)
		return
	}
	fmt.Println(state.Wallpaper)
}

func handleApply(paths files.Paths) {
	if len(os.Args) < 3 {
		die(errors.New("missing image path"))
	}
	img := os.Args[2]
	if !filepath.IsAbs(img) {
		abs, err := filepath.Abs(img)
		if err == nil {
			img = abs
		}
	}
	if _, err := os.Stat(img); err != nil {
		die(fmt.Errorf("image does not exist: %w", err))
	}

	pal, err := colors.ExtractFromImage(img)
	if err != nil {
		die(err)
	}
	if err := system.EnsureAwwwDaemon(); err != nil {
		die(err)
	}
	if err := system.ApplyWallpaper(img, system.Transition{Type: "grow", Step: 90, Pos: "top"}); err != nil {
		die(err)
	}
	if _, err := theme.WriteAll(paths, pal, img); err != nil {
		die(err)
	}
	if err := firefox.SyncPywalfox(paths, pal, img); err != nil {
		die(err)
	}
	system.EnableOhMyPoshReload()
	system.TouchGTKFiles(paths.Home)
	system.RestartDesktopServices()
	fmt.Println("ok")
}

func handleApps(paths files.Paths) {
	items, err := apps.List(paths.Home, hasFlag("--refresh"))
	if err != nil {
		die(err)
	}
	if hasFlag("--json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		_ = enc.Encode(items)
		return
	}
	for _, item := range items {
		fmt.Printf("%s\t%s\n", item.ID, item.Name)
	}
}

func handleLaunch(paths files.Paths) {
	if len(os.Args) < 3 {
		die(errors.New("missing desktop id"))
	}
	id := os.Args[2]
	if err := apps.Launch(paths.Home, id); err != nil {
		die(err)
	}
	fmt.Println("ok")
}

func splitLines(s string) []string {
	lines := make([]string, 0, 32)
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			lines = append(lines, s[start:i])
			start = i + 1
		}
	}
	if start < len(s) {
		lines = append(lines, s[start:])
	}
	return lines
}

func hasFlag(flag string) bool {
	for _, a := range os.Args[2:] {
		if a == flag {
			return true
		}
	}
	return false
}

func die(err error) {
	fmt.Fprintf(os.Stderr, "wpctl: %v\n", err)
	os.Exit(1)
}
