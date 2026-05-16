-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
--      ____        __          --
--     / __ \__  __/ /__  _____ --
--    / /_/ / / / / / _ \/ ___/ --
--   / _, _/ /_/ / /  __(__  )  --
--  /_/ |_|\__,_/_/\___/____/   --
--                              --
-- ~~~~~ Windows & Layers ~~~~~ --


-- Ignores maximize requests from apps
hl.window_rule({
    name = "windowrule-1",
    match = {class = ".*"},
    suppress_event = "maximize"
})

-- Old dragging issues with XWayland
hl.window_rule({
    name = "windowrule-2",
    stay_focused = false,
    match = {
        class = "^$",
        title = "^$",
        xwayland = "^$",
        float = true,
        fullscreen = false,
        pin = false
    },
})

-- ~~~~~~~ Program windowrules ~~~~~~~~ --

hl.window_rule({
    name = "windowrule-3",
    opacity = "0.8 override",
    match = {class = "code"}
})


hl.window_rule({
    name = "windowrule-4",
    opacity = "0.8 override",
    match = {class = "firefox"}
})

hl.window_rule({
    name = "windowrule-5",
    float = true,
    center = true,
    size = {"(monitor_w*0.4)", "(monitor_h*0.4)"},
    opacity = "0.8 override",
    stay_focused = true,
    match = {title = "(system_update)"}  
})

hl.window_rule({
    name = "windowrule-6",
    opacity = "0.9 override",
    match = {class = "obsidian"}
})

-- To keep quickshell master popup as floating utility window
hl.window_rule({
    name = "windowrule-9",
    float = true,
    pin = true,
    border_size = 0,
    no_blur = true,
    no_anim = true,
    rounding = 10,
    match = {title = "^(qs-master)"}
})

-- ~~~~~~~~~~~~ Layerrules ~~~~~~~~~~~~ --

hl.layer_rule({
    name = "layerrule-1",
    blur = true,
    ignore_alpha = 0.1,
    match = {namespace = "logout_dialog"}
})

hl.layer_rule({
    name = "qs-bar",
    blur = true,
    ignore_alpha = 0.5,
    match = {namespace = "qs-shell:bar"}
})

hl.layer_rule({
    name = "qs-launcher",
    blur = true,
    ignore_alpha = 0.05,
    match = {namespace = "qs-shell:launcher"}
})

hl.layer_rule({
    name = "qs-wallpaper",
    blur = true,
    ignore_alpha = 0.5,
    match = {namespace = "qs-shell:wallpaper-picker"}
})

hl.layer_rule({
    name = "qs-network",
    blur = true,
    ignore_alpha = 0.05,
    match = {namespace = "qs-shell:network"}
})

hl.layer_rule({
    name = "qs-bluetooth",
    blur = true,
    ignore_alpha = 0.05,
    match = {namespace = "qs-shell:bluetooth"}
})

hl.layer_rule({
    name = "qs-notifications",
    blur = true,
    ignore_alpha = 0.05,
    match = {namespace = "qs-shell:notifications"}
})

hl.layer_rule({
    name = "qs-osd",
    blur = true,
    ignore_alpha = 0.2,
    match = {namespace = "qs-shell:osd"}
})
