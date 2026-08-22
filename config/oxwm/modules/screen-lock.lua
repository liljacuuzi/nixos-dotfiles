-------------------------------------------------------------------------------
-- Screen Lock & Idle Management Module
-------------------------------------------------------------------------------

local M = {}

function M.setup()
    local idle_cmd = 'xidlehook ' ..
        '--not-when-fullscreen ' ..
        '--not-when-audio ' ..
        '--timer 270 "notify-send \'Screen Lock\' \'Locking in 30 seconds...\' -u normal" "" ' ..
        '--timer 30 "xsecurelock" ""'

    oxwm.autostart(idle_cmd)
end

return M
