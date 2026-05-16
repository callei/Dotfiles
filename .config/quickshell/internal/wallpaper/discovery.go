package wallpaper

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type Item struct {
	Name string `json:"name"`
	Path string `json:"path"`
}

var supportedExt = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

func List(dir string) ([]Item, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("read wallpaper dir %s: %w", dir, err)
	}

	items := make([]Item, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		ext := strings.ToLower(filepath.Ext(e.Name()))
		if !supportedExt[ext] {
			continue
		}
		items = append(items, Item{
			Name: e.Name(),
			Path: filepath.Join(dir, e.Name()),
		})
	}

	sort.Slice(items, func(i, j int) bool {
		return strings.ToLower(items[i].Name) < strings.ToLower(items[j].Name)
	})
	return items, nil
}
