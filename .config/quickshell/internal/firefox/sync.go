package firefox

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"quickshell/internal/colors"
	"quickshell/internal/files"
)

func SyncPywalfox(paths files.Paths, pal colors.Palette, wallpaper string) error {
	if err := writeWalCache(paths.WalCacheDir, pal, wallpaper); err != nil {
		return err
	}
	if _, err := exec.LookPath("pywalfox"); err != nil {
		return nil
	}
	cmd := exec.Command("pywalfox", "update")
	out, err := cmd.CombinedOutput()

	logPath := filepath.Join(paths.WalCacheDir, "pywalfox-sync.log")
	status := "ok"
	if err != nil {
		status = err.Error()
	}
	_ = os.WriteFile(logPath, []byte(fmt.Sprintf("time=%s\nstatus=%s\noutput=%s\n", time.Now().Format(time.RFC3339), status, strings.TrimSpace(string(out)))), 0o644)

	// pywalfox is optional; wallpaper/apply should continue even when browser sync fails.
	return nil
}

func writeWalCache(cacheDir string, pal colors.Palette, wallpaper string) error {
	if err := os.MkdirAll(cacheDir, 0o755); err != nil {
		return fmt.Errorf("mkdir wal cache: %w", err)
	}

	var colorsTxt strings.Builder
	for i := 0; i < 16; i++ {
		colorsTxt.WriteString(strings.ToLower(pal.Colors[i]))
		colorsTxt.WriteString("\n")
	}
	if err := os.WriteFile(cacheDir+"/colors", []byte(colorsTxt.String()), 0o644); err != nil {
		return fmt.Errorf("write colors: %w", err)
	}

	if err := os.WriteFile(cacheDir+"/wal", []byte(wallpaper+"\n"), 0o644); err != nil {
		return fmt.Errorf("write wal path: %w", err)
	}

	var sh strings.Builder
	fmt.Fprintf(&sh, "wallpaper='%s'\n", wallpaper)
	fmt.Fprintf(&sh, "background='%s'\n", pal.Colors[0])
	fmt.Fprintf(&sh, "foreground='%s'\n", pal.Colors[7])
	fmt.Fprintf(&sh, "cursor='%s'\n", pal.Colors[7])
	for i := 0; i < 16; i++ {
		fmt.Fprintf(&sh, "color%d='%s'\n", i, pal.Colors[i])
	}
	if err := os.WriteFile(cacheDir+"/colors.sh", []byte(sh.String()), 0o644); err != nil {
		return fmt.Errorf("write colors.sh: %w", err)
	}

	var css strings.Builder
	for i := 0; i < 16; i++ {
		fmt.Fprintf(&css, "@define-color color%d %s;\n", i, pal.Colors[i])
	}
	fmt.Fprintf(&css, "@define-color background %s;\n", pal.Colors[0])
	fmt.Fprintf(&css, "@define-color foreground %s;\n", pal.Colors[7])
	if err := os.WriteFile(cacheDir+"/colors.css", []byte(css.String()), 0o644); err != nil {
		return fmt.Errorf("write colors.css: %w", err)
	}

	colorsMap := make(map[string]string, 16)
	for i := 0; i < 16; i++ {
		colorsMap[fmt.Sprintf("color%d", i)] = pal.Colors[i]
	}
	colorsJSON := map[string]any{
		"wallpaper": wallpaper,
		"alpha":     "100",
		"special": map[string]string{
			"background": pal.Colors[0],
			"foreground": pal.Colors[7],
			"cursor":     pal.Colors[7],
		},
		"colors": colorsMap,
	}
	jsonOut, err := json.MarshalIndent(colorsJSON, "", "    ")
	if err != nil {
		return fmt.Errorf("marshal colors.json: %w", err)
	}
	jsonOut = append(jsonOut, '\n')
	if err := os.WriteFile(cacheDir+"/colors.json", jsonOut, 0o644); err != nil {
		return fmt.Errorf("write colors.json: %w", err)
	}

	return nil
}
