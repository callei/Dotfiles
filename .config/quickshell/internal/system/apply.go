package system

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
)

type Transition struct {
	Type string
	Step int
	Pos  string
}

func EnsureAwwwDaemon() error {
	if exec.Command("pgrep", "awww-daemon").Run() == nil {
		return nil
	}
	cmd := exec.Command("awww-daemon")
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("start awww-daemon: %w", err)
	}
	return nil
}

func ApplyWallpaper(path string, t Transition) error {
	args := []string{"img", path, "--transition-type", t.Type, "--transition-step", strconv.Itoa(t.Step), "--transition-pos", t.Pos}
	if out, err := exec.Command("awww", args...).CombinedOutput(); err != nil {
		return fmt.Errorf("awww img failed: %w: %s", err, strings.TrimSpace(string(out)))
	}
	return nil
}

func RestartDesktopServices() {
	_ = exec.Command("pkill", "swayosd-server").Run()
	_ = exec.Command("swayosd-server", "--top-margin=0.85").Start()

	_ = exec.Command("pkill", "swaync").Run()

	_ = exec.Command("hyprctl", "reload").Run()
	if exec.Command("pgrep", "-x", "waybar").Run() == nil {
		_ = exec.Command("pkill", "-RTMIN+1", "waybar").Run()
	}
	if exec.Command("pgrep", "-x", "nautilus").Run() == nil {
		_ = exec.Command("nautilus", "-q").Run()
	}
	reloadKitty()
}

func TouchGTKFiles(home string) {
	_ = exec.Command("touch", home+"/.config/gtk-3.0/gtk.css").Run()
	_ = exec.Command("touch", home+"/.config/gtk-4.0/gtk.css").Run()
}

func EnableOhMyPoshReload() {
	if _, err := exec.LookPath("oh-my-posh"); err != nil {
		return
	}
	_ = exec.Command("oh-my-posh", "enable", "reload").Run()
}

func reloadKitty() {
	out, err := exec.Command("pgrep", "-x", "kitty").Output()
	if err != nil {
		return
	}
	pids := strings.Fields(string(out))
	for _, pidStr := range pids {
		pid, err := strconv.Atoi(pidStr)
		if err != nil {
			continue
		}
		proc, err := os.FindProcess(pid)
		if err != nil {
			continue
		}
		_ = proc.Signal(syscall.SIGUSR1)
	}
}
