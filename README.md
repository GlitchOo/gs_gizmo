# GS_GIZMO

This is a simple gizmo for RedM similar to the gizmo in FxDK and FiveM.
Can be useful for creating an intuitive experience in housing systems.

[Example - Camera Mode Enabled](https://youtu.be/sywltl8HtcY)

[Example - Camera Mode Disabled](https://youtu.be/bqQzilknLmI)

![Preview 1](https://i.gyazo.com/ba9aa91325101002b7be2b0d1eb3cc45.jpg)

## Export (Client)

You can override the config via the export
- EnableCam: Enable/Disable camera mode
- MaxDistance: Override the MaxDistance (Camera Mode)
- MinY: Override the MinY (Camera Mode)
- MaxY: Override the MaxY (Camera Mode)
- MovementSpeed: Override movement speed (Camera Mode)

```lua
--- Toggle the gizmo on the entity
--- @param Entity number
--- @return table
local data = exports.gs_gizmo:Toggle(Entity, {
    EnableCam = true,
    MaxDistance = 100,
    MinY = -40,
    MaxY = 40,
    MovementSpeed = 0.1
})
```

Data is returned in the following format:

```lua
{
    "coords": {
        "x": -233.07241821289063,
        "y": 602.7467651367188,
        "z": 112.32718658447266
    },
    "rotation": {
        "x": 0.0,
        "y": 0.0,
        "z": 0.0
    },
    "entity": 969988
}
```