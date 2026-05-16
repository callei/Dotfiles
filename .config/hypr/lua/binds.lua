-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
--      ____  _           __      --
--     / __ )(_)___  ____/ /____  --
--    / __  / / __ \/ __  / ___/  --
--   / /_/ / / / / / /_/ (__  )   --
--  /_____/_/_/ /_/\__,_/____/    --
--                                --
-- ~~~~~~ Shortcuts & More ~~~~~~ --                            

local mainMod = "SUPER"

-- --- Terminal & Base-apps ---
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(apps.terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + M",      hl.dsp.window.fullscreen({ action = "set" }))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(apps.fileManager))
hl.bind(mainMod .. " + T",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(apps.browser))
hl.bind(mainMod .. " + C",      hl.dsp.exec_cmd(apps.editor))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd(apps.locker))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("wlogout"))

-- --- Quickshell controls ---
local qs = "/home/calle/.config/quickshell/bin/qs_control.sh "

hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.exec_cmd(qs .. "launcher"))
hl.bind(mainMod .. " + CTRL + B",      hl.dsp.exec_cmd(qs .. "bluetooth"))
hl.bind(mainMod .. " + CTRL + N",      hl.dsp.exec_cmd(qs .. "notifications"))
hl.bind(mainMod .. " + W",             hl.dsp.exec_cmd(qs .. "wallpaper"))
hl.bind(mainMod .. " + D",             hl.dsp.exec_cmd(qs .. "launcher"))
hl.bind(mainMod .. " + V",             hl.dsp.exec_cmd(qs .. "volume"))
hl.bind(mainMod .. " + A",             hl.dsp.exec_cmd(qs .. "network"))

-- --- Window management (Resize/Swap/Focus) ---
-- Resize
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 100, y = 0 }))
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -100, y = 0 }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 100 }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -100 }))

-- Swap
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- --- Workspaces ---
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

-- Loop for 1-10 workspace switching
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- --- Multimedia & Laptop (with flags) ---
local audio_flags = { repeating = true, locked = true }

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(qs .. "volume-up"), audio_flags)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(qs .. "volume-down"), audio_flags)
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(qs .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(qs .. "mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd(qs .. "brightness-up"), audio_flags)
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd(qs .. "brightness-down"), audio_flags)

-- Power/Sleep
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("XF86Sleep",    hl.dsp.exec_cmd("systemctl suspend"), { locked = true })

-- --- Mouse & Scrolling ---
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Window dragging/resizing (Mouse binds uses  hl.dsp.window.drag/resize)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Lock when closing lid
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprlock --immediate && systemctl suspend"), { locked = true })

-- --- Screenshot ---
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[slurp | xargs -I {} sh -c 'sleep 0.1 && grim -g "{}" ~/Bilder/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && wl-copy < ~/Bilder/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png']]))


