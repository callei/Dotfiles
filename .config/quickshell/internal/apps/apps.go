package apps

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

const appCacheVersion = 7

type App struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Exec     string `json:"exec"`
	Icon     string `json:"icon"`
	IconPath string `json:"iconPath"`
	Terminal bool   `json:"terminal"`
}

type appCache struct {
	Version int   `json:"version"`
	SavedAt int64 `json:"savedAt"`
	Apps    []App `json:"apps"`
}

func List(home string, refresh bool) ([]App, error) {
	if cached, savedAt, ok := readCache(home); ok {
		if !refresh {
			changed, err := desktopEntriesChanged(home, savedAt)
			if err != nil || !changed {
				return cached, nil
			}
		}
	}

	dirs := []string{
		filepath.Join(home, ".local", "share", "applications"),
		filepath.Join(home, ".local", "share", "flatpak", "exports", "share", "applications"),
		"/usr/local/share/applications",
		"/usr/share/applications",
		"/var/lib/flatpak/exports/share/applications",
	}

	seen := map[string]bool{}
	iconCache := map[string]string{}
	apps := make([]App, 0, 300)

	for _, dir := range dirs {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, e := range entries {
			if e.IsDir() || !strings.HasSuffix(e.Name(), ".desktop") {
				continue
			}
			id := e.Name()
			if seen[id] {
				continue
			}
			app, ok := parseDesktop(home, filepath.Join(dir, e.Name()), id, iconCache)
			if !ok {
				continue
			}
			seen[id] = true
			apps = append(apps, app)
		}
	}

	sort.Slice(apps, func(i, j int) bool {
		return strings.ToLower(apps[i].Name) < strings.ToLower(apps[j].Name)
	})
	_ = writeCache(home, apps)
	return apps, nil
}

func Launch(home, id string) error {
	apps, err := List(home, false)
	if err != nil {
		return err
	}
	for _, app := range apps {
		if app.ID != id {
			continue
		}
		return launchApp(app)
	}
	return fmt.Errorf("app not found: %s", id)
}

func launchApp(app App) error {
	cmdline := cleanExec(app.Exec)
	var cmd *exec.Cmd
	if cmdline == "" {
		cmd = exec.Command("gtk-launch", app.ID)
	} else if app.Terminal {
		cmd = exec.Command("kitty", "-e", "sh", "-lc", cmdline)
	} else {
		cmd = exec.Command("sh", "-lc", cmdline)
	}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("launch %s: %w", app.Name, err)
	}
	return nil
}

func parseDesktop(home, path, id string, iconCache map[string]string) (App, bool) {
	f, err := os.Open(path)
	if err != nil {
		return App{}, false
	}
	defer f.Close()

	inEntry := false
	name := ""
	execLine := ""
	icon := ""
	noDisplay := false
	hidden := false
	entryType := ""
	terminal := false

	s := bufio.NewScanner(f)
	for s.Scan() {
		line := strings.TrimSpace(s.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "[") {
			inEntry = line == "[Desktop Entry]"
			continue
		}
		if !inEntry {
			continue
		}
		kv := strings.SplitN(line, "=", 2)
		if len(kv) != 2 {
			continue
		}
		key := strings.TrimSpace(kv[0])
		val := strings.TrimSpace(kv[1])
		switch key {
		case "Type":
			entryType = val
		case "Name":
			if name == "" {
				name = val
			}
		case "Exec":
			execLine = val
		case "Icon":
			icon = val
		case "NoDisplay":
			noDisplay = strings.EqualFold(val, "true")
		case "Hidden":
			hidden = strings.EqualFold(val, "true")
		case "Terminal":
			terminal = strings.EqualFold(val, "true")
		}
	}

	if err := s.Err(); err != nil {
		return App{}, false
	}
	if entryType != "Application" || noDisplay || hidden || name == "" {
		return App{}, false
	}
	return App{
		ID:       id,
		Name:     name,
		Exec:     execLine,
		Icon:     icon,
		IconPath: resolveIconPath(home, icon, iconCache),
		Terminal: terminal,
	}, true
}

func resolveIconPath(home, icon string, cache map[string]string) string {
	if icon == "" {
		return ""
	}
	icon = strings.TrimPrefix(icon, "file://")
	if cached, ok := cache[icon]; ok {
		return cached
	}

	candidates := []string{icon}
	if !strings.HasSuffix(icon, "-symbolic") {
		candidates = append(candidates, icon+"-symbolic")
	}

	for _, c := range candidates {
		if filepath.IsAbs(c) {
			if _, err := os.Stat(c); err == nil && isImagePath(c) {
				cache[icon] = c
				return c
			}
		}
	}

	allMatches := make([]string, 0, 64)

	roots := []string{
		filepath.Join(home, ".icons"),
		filepath.Join(home, ".local", "share", "icons"),
		"/usr/share/icons",
		filepath.Join(home, ".local", "share", "pixmaps"),
		"/usr/share/pixmaps",
	}

	categories := []string{"apps", "devices", "actions", "status", "categories", "places", "mimetypes", "emblems", "panel", "legacy"}
	exts := []string{".png", ".svg", ".xpm"}

	for _, root := range roots {
		for _, name := range candidates {
			// Some desktop files ship relative icon paths with extension already included.
			if strings.Contains(name, "/") || filepath.Ext(name) != "" {
				directPath := filepath.Join(root, name)
				if _, err := os.Stat(directPath); err == nil && isImagePath(directPath) {
					allMatches = append(allMatches, directPath)
				}
			}
			for _, ext := range exts {
				direct := filepath.Join(root, name+ext)
				if _, err := os.Stat(direct); err == nil && isImagePath(direct) {
					allMatches = append(allMatches, direct)
				}

				for _, cat := range categories {
					patterns := []string{
						filepath.Join(root, "hicolor", "*", cat, name+ext),
						filepath.Join(root, "*", "*", cat, name+ext),
						filepath.Join(root, "*", cat, "*", name+ext),
						filepath.Join(root, "*", cat, name+ext),
					}
					for _, pattern := range patterns {
						matches, err := filepath.Glob(pattern)
						if err != nil || len(matches) == 0 {
							continue
						}
						allMatches = append(allMatches, matches...)
					}
				}
			}
		}
	}

	if len(allMatches) > 0 {
		best := pickBestIconMatch(allMatches)
		cache[icon] = best
		return best
	}

	for _, alias := range iconAliases(icon) {
		if alias == "" || strings.EqualFold(alias, icon) {
			continue
		}
		if p := resolveIconPath(home, alias, cache); p != "" {
			cache[icon] = p
			return p
		}
	}

	cache[icon] = ""
	return ""
}

func iconAliases(icon string) []string {
	switch strings.ToLower(strings.TrimSpace(icon)) {
	case "hwloc", "lstopo":
		return []string{"utilities-system-monitor", "applications-system", "computer"}
	default:
		return nil
	}
}

func pickBestIconMatch(matches []string) string {
	best := ""
	bestScore := -1 << 30
	seen := map[string]bool{}

	for _, m := range matches {
		if m == "" || seen[m] {
			continue
		}
		seen[m] = true
		score := scoreIconPath(m)
		if score > bestScore || (score == bestScore && m < best) {
			bestScore = score
			best = m
		}
	}

	return best
}

func scoreIconPath(path string) int {
	score := 0
	lower := strings.ToLower(path)

	// Avoid legacy buckets unless nothing else is available.
	if strings.Contains(lower, "adwaitalegacy") || strings.Contains(lower, "/legacy/") {
		score -= 120
	}

	// Prefer vector icons when available for clean scaling.
	if strings.HasSuffix(lower, ".svg") {
		score += 30
	}

	// Prefer full-color assets for launcher tiles when both exist.
	if strings.Contains(lower, "-symbolic") || strings.Contains(lower, "/symbolic/") {
		score -= 35
	}

	// Prefer larger nominal icon sizes.
	parts := strings.Split(filepath.ToSlash(lower), "/")
	maxSize := 0
	for _, p := range parts {
		if p == "scalable" {
			if maxSize < 256 {
				maxSize = 256
			}
			continue
		}
		x := strings.Index(p, "x")
		if x <= 0 {
			n, err := strconv.Atoi(p)
			if err == nil && n > maxSize {
				maxSize = n
			}
			continue
		}
		n, err := strconv.Atoi(p[:x])
		if err == nil && n > maxSize {
			maxSize = n
		}
	}
	score += maxSize

	return score
}

func isImagePath(path string) bool {
	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	case ".png", ".svg", ".xpm":
		return true
	default:
		return false
	}
}

func cachePath(home string) string {
	return filepath.Join(home, ".cache", "quickshell-shell", "apps-cache.json")
}

func readCache(home string) ([]App, int64, bool) {
	path := cachePath(home)
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, 0, false
	}
	var c appCache
	if err := json.Unmarshal(b, &c); err != nil {
		return nil, 0, false
	}
	if c.Version != appCacheVersion {
		return nil, 0, false
	}
	if c.SavedAt <= 0 || len(c.Apps) == 0 {
		return nil, 0, false
	}
	return c.Apps, c.SavedAt, true
}

func desktopEntriesChanged(home string, savedAt int64) (bool, error) {
	cutoff := time.Unix(savedAt, 0)
	dirs := []string{
		filepath.Join(home, ".local", "share", "applications"),
		filepath.Join(home, ".local", "share", "flatpak", "exports", "share", "applications"),
		"/usr/local/share/applications",
		"/usr/share/applications",
		"/var/lib/flatpak/exports/share/applications",
	}

	for _, dir := range dirs {
		info, err := os.Stat(dir)
		if err != nil {
			continue
		}
		if info.ModTime().After(cutoff) {
			return true, nil
		}

		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, e := range entries {
			if e.IsDir() || !strings.HasSuffix(e.Name(), ".desktop") {
				continue
			}
			ei, err := e.Info()
			if err != nil {
				continue
			}
			if ei.ModTime().After(cutoff) {
				return true, nil
			}
		}
	}

	return false, nil
}

func writeCache(home string, apps []App) error {
	path := cachePath(home)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	payload := appCache{
		Version: appCacheVersion,
		SavedAt: time.Now().Unix(),
		Apps:    apps,
	}
	b, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	return os.WriteFile(path, b, 0o644)
}

func cleanExec(execLine string) string {
	replacer := strings.NewReplacer(
		"%f", "", "%F", "", "%u", "", "%U", "", "%d", "", "%D", "",
		"%n", "", "%N", "", "%i", "", "%c", "", "%k", "", "%v", "", "%m", "", "%%", "%",
	)
	out := replacer.Replace(execLine)
	out = strings.TrimSpace(out)
	parts := strings.Fields(out)
	return strings.Join(parts, " ")
}
