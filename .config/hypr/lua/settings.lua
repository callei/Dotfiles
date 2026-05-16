-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
--                                         --
--   _____      __  __  _                  --  
--  / ___/___  / /_/ /_(_)___  ____ ______ --
--  \__ \/ _ \/ __/ __/ / __ \/ __ `/ ___/ --
-- ___/ /  __/ /_/ /_/ / / / / /_/ (__  )  --
--/____/\___/\__/\__/_/_/ /_/\__, /____/   --
--                          /____/         --
--                                         --
-- ~~~~~~~~ Animations & General ~~~~~~~~~ --

-- Environment variables --

hl.env("XDG_CONFIG_HOME", "/home/calle/.config")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")


-- Permissions --

hl.permission("/usr/bin/grim", "screencopy", "allow")
hl.permission("/usr/local/bin/grim", "screencopy", "allow")

-- Future hyprprm integration
hl.permission("/usr/bin/hyprpm", "plugin", "allow")

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function readThemeVar(name, fallback)
  local home = os.getenv("HOME")
  local path = home .. "/.config/themes/current.conf"
  local f = io.open(path, "r")
  if not f then
    return fallback
  end
  for line in f:lines() do
    local value = line:match("^%$" .. name .. "%s*=%s*(.+)$")
    if value then
      f:close()
      return trim(value)
    end
  end
  f:close()
  return fallback
end

local accent = readThemeVar("accent", "rgba(33ccffee)")
local accentAlt = readThemeVar("color4", accent)

hl.config({
  general = {
    gaps_in = { top = 5, right = 10, bottom = 10, left = 10 },
    gaps_out = { top = 5, right = 20, bottom = 20, left = 20 },
    border_size = 2,
    layout = "dwindle",
    resize_on_border = true,
    ["col.active_border"] = {colors = {accent, accentAlt}, angle = 45},
    ["col.inactive_border"] = "rgba(00000000)",
    allow_tearing = false
  },

  decoration = {
    rounding = 10,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.9,

    shadow = {
      enabled = true,
      range = 20,
      render_power = 2,
      color = "rgba(1a1a1a30)"
    },

    blur = {
      enabled = true,
      size = 3,
      passes = 4,
      xray = false,
      popups = true,
      new_optimizations = true,
      ignore_opacity = true
    }
  }
})

-- layout config --
hl.config({
  dwindle = {
    preserve_split = true
  },
  master = {
    new_status = "master"
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true
  }
})

-- input & gestures --
hl.config({
  input = {
    kb_layout = "se",
    kb_variant = "nodeadkeys",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {natural_scroll = true}
  }
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace"
})

hl.device({
  name = "syna3091:00-06cb:82f5-mouse",
  sensitivity = 0
})
