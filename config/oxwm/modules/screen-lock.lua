-------------------------------------------------------------------------------
-- Screen Lock & Idle Management Module
--
-- Timeline (defaults):
--   0:00 ──idle──► 2:30  warning notification appears
--   2:30 ──────────► 3:00  notification dismissed, screen locks
--   Any input during the last 30 s cancels the lock AND the notification.
-------------------------------------------------------------------------------

local M       = {}

M.lock_after  = 300 -- total idle seconds before locking (3 min)
M.warn_before = 30  -- show warning this many seconds before locking

local BIN     = "/run/current-system/sw/bin"

function M.setup(opts)
    opts              = opts or {}
    local lock_after  = opts.lock_after or M.lock_after
    local warn_before = opts.warn_before or M.warn_before
    local warn_at     = lock_after - warn_before

    assert(warn_at > 0, "screen-lock: warn_before must be < lock_after")

    local idle_cmd =
        "xidlehook " ..
        "--not-when-fullscreen " ..
        "--not-when-audio " ..
        string.format("--timer %d '%s/oxwm-lock-warn %d' '' ", warn_at, BIN, warn_before) ..
        string.format("--timer %d '%s/oxwm-lock' '%s/oxwm-lock-dismiss'", warn_before, BIN, BIN)

    oxwm.autostart(idle_cmd)
end

return M
