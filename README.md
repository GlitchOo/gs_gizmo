# GS_GIZMO

![Main](https://github.com/GlitchOo/gs_gizmo/actions/workflows/main.yml/badge.svg)

This is a simple gizmo for RedM similar to the gizmo in FxDK and FiveM.
Can be useful for creating an intuitive experience in housing systems.

[Example - Camera Mode Enabled](https://youtu.be/sywltl8HtcY)

[Example - Camera Mode Disabled](https://youtu.be/bqQzilknLmI)

![Preview 1](https://i.gyazo.com/fd89f9a9018aa44f640db5d22787b9a7.jpg)

## Export (Client)

You can override the config via the export
- EnableCam: Enable/Disable camera mode
- MaxDistance: Override the MaxDistance for the gizmo (set to false for no limit)
- MaxCamDistance:  Override the MaxCamDistance for "camera mode"
- MinY: Override the MinY (Camera Mode)
- MaxY: Override the MaxY (Camera Mode)
- MovementSpeed: Override movement speed (Camera Mode)

```lua
--- Toggle the gizmo on the entity
--- @param Entity number
--- @param Config table
--- @param fn function | nil
--- @return table
local data = exports.gs_gizmo:Toggle(Entity, {
    EnableCam = true,
    MaxDistance = 100,
    MaxCamDistance = 60,
    MinY = -40,
    MaxY = 40,
    MovementSpeed = 0.1
}, 
function(pos)
    -- You can hook in a function to block/allow gizmo and camera movement
    -- pos: vec3
    -- return: boolean
    return true
end)
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

# Build UI

Building the UI is reletively easy. Just make sure you have Node 18.x or higher installed and pnpm

Navigate to the ./web directory and execute the following commands

## pnpm
pnpm i

pnpm run build

## npm
npm i

npm run build


# Credits
[DemiAutomatic](https://github.com/DemiAutomatic)