#!/usr/bin/env python3
import subprocess
import time
import os

def get_gsetting(schema, key):
    try:
        result = subprocess.check_output(["gsettings", "get", schema, key], stderr=subprocess.DEVNULL).decode().strip()
        if result.startswith("'") and result.endswith("'"):
            result = result[1:-1]
        return result
    except Exception:
        return None

def set_gsetting(schema, key, value):
    try:
        subprocess.run(["gsettings", "set", schema, key, value], check=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        pass

def reload_gtk():
    schema = "org.gnome.desktop.interface"
    key_theme = "gtk-theme"
    current_theme = get_gsetting(schema, key_theme)
    if current_theme:
        set_gsetting(schema, key_theme, "")
        time.sleep(0.1)
        set_gsetting(schema, key_theme, current_theme)
    # Touch the gtk.css files to update timestamp
    try:
        home = os.environ['HOME']
        subprocess.run(["touch", f"{home}/.config/gtk-3.0/gtk.css"])
        subprocess.run(["touch", f"{home}/.config/gtk-4.0/gtk.css"])
    except Exception:
        pass

if __name__ == "__main__":
    reload_gtk()
