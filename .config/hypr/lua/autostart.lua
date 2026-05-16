-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
--     ___         __             __             __  --
--    /   | __  __/ /_____  _____/ /_____ ______/ /_ --
--   / /| |/ / / / __/ __ \/ ___/ __/ __ `/ ___/ __/ --
--  / ___ / /_/ / /_/ /_/ (__  ) /_/ /_/ / /  / /_   --
-- /_/  |_\__,_/\__/\____/____/\__/\__,_/_/   \__/   --
--                                                   --
-- ~~~~~~~~~~~~~~~~ Startup Scripts ~~~~~~~~~~~~~~~  --

hl.on("hyprland.start", function()
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg")
    hl.exec_cmd("pipewire-pulse &")
    hl.exec_cmd("quickshell -p ~/.config/quickshell/quickshell/shell.qml -d")

-- The following syncs my mic mute light with the button.
    hl.exec_cmd("~/.config/quickshell/bin/qs_control.sh sync-mic-led")

    hl.exec_cmd("hypridle")
end)
