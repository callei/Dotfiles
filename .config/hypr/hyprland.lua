-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
--                                                                    --
--      ______      ____    _                           _____         --
--     / ____/___ _/ / /__ ( )_____   _________  ____  / __(_)___ _   --
--    / /   / __ `/ / / _ \|// ___/  / ___/ __ \/ __ \/ /_/ / __ `/   --
--   / /___/ /_/ / / /  __/ (__  )  / /__/ /_/ / / / / __/ / /_/ /    --
--   \____/\__,_/_/_/\___/ /____/   \___/\____/_/ /_/_/ /_/\__, /     --
--                                                        /____/      --
--                                                                    -- 
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  --
--  HYPRLAND MAIN CONFIG (v0.55+ Lua Edition)                         --
--                                                                    --
--  This is the main file that loads in every module from             --
--  the folder ./lua/                                                 --
--                                                                    --
--  Structure:                                                        --
--    1. Apps       - Definitions of terminal, browser  av terminal,  --
--                    browser, etc.                                   -- 
--    2. Settings   - General, Input, Decoration, Animations          --
--    3. Autostart  - System services and applications in the         --
--                    background                                      --
--    4. Rules      - Window- and Layer-rules                         --
--    5. Binds      - All keybinds                                    --
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --

-- ~~~~~~~~~~~~~~~~~~ 1. Imports and Sources ~~~~~~~~~~~~~~~~~~~~~~~~ --

-- Global variables for programs
_G.apps = require("lua.apps")

-- System settings and environment
require("lua.settings")
require("wallpaper") -- wallpaper and lockscreen with awww
require("lua.autostart")

-- Window management and binds
require("lua.rules")
require("lua.binds")
require("lua.animations")

-- ~~~~~~~~~~~~~~~~~~~~~~~ 2. Monitor ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --

hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "0x0",
  scale = 1
})
