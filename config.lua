Config = {
    DevMode = false,                                    -- Enable/Disable Dev Mode

    Locale = 'en',                                      -- Locale to use

    EnableCam = true,                                   -- Enable/Disable camera feature
    MaxDistance = 100,                                  -- Max disatnce the gizmo can be moved from the starting position (set to false to disable)
    MaxCamDistance = 80,                                -- Max distance the camera can be moved from the player
    MinY = -40,                                         -- Min Y value from starting position for camera
    MaxY = 40,                                          -- Max Y value starting position for camera
    MovementSpeed = 0.1,                                -- Movement speed for camera


    -- Keybinds (do not use w, a, s, d, q, and e)
    Keybinds = {
        ToggleMode = 'R',                               -- Keybind to toggle rotate mode
        SnapToGround = 'G',                             -- Keybind to snap to ground
        Cancel = 'X',                                   -- Keybind to cancel editing
        Finish = 'ENTER',                               -- Keybind to finish editing
    }
}