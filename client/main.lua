local gizmoActive = false
local responseData = nil
local mode = 'translate'
local cam = nil
local enableCam
local maxDistance
local maxCamDistance
local minY
local maxY
local movementSpeed
local stored
local hookedFunc

--- Export Handler
--- @param resourceName string
--- @param exportName string
--- @param fn function
local function ExportHandler(resourceName, exportName, fn)
    AddEventHandler(('__cfx_export_%s_%s'):format(resourceName, exportName), function(cb)
        cb(fn)
    end)
end

--- Initializes UI focus, camera, and other misc
--- @param bool boolean
local function Init(bool)
    local ped = PlayerPedId()
    if bool then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)

        if enableCam then
            local coords = GetGameplayCamCoord()
            local rot = GetGameplayCamRot(2)
            local fov = GetGameplayCamFov()

            cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

            SetCamCoord(cam, coords.x, coords.y, coords.z + 0.5)
            SetCamRot(cam, rot.x, rot.y, rot.z, 2)
            SetCamFov(cam, fov)
            RenderScriptCams(true, true, 500, true, true)
            FreezeEntityPosition(ped, true)
        end
        
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(IsNuiFocusKeepingInput())
        FreezeEntityPosition(ped, false)

        if cam then
            RenderScriptCams(false, true, 500, true, true)
            SetCamActive(cam, false)
            DetachCam(cam)
            DestroyCam(cam, true)
            cam = nil
        end

        stored = nil
        hookedFunc = nil
        
        SendNUIMessage({
            action = 'SetupGizmo',
            data = {
                handle = nil,
            }
        })
    end

    gizmoActive = bool
end

--- Disables controls, Radar, and Player Firing
function DisableControlsAndUI()
    DisableControlAction(0, 0x07CE1E61, true)
    HideHudAndRadarThisFrame()
    DisablePlayerFiring(U.Cache.PlayerId, true)
end

--- Get the normal value of a control(s) used for movement & rotation
--- @param control number | table
--- @return number
local function GetSmartControlNormal(control)
    if type(control) == 'table' then
        local normal1 = GetDisabledControlNormal(0, control[1])
        local normal2 = GetDisabledControlNormal(0, control[2])
        return normal1 - normal2
    end

    return GetDisabledControlNormal(0, control)
end

--- Handle camera rotations
local function Rotations()
    local newX
    local rAxisX = GetControlNormal(0, 0xA987235F)
    local rAxisY = GetControlNormal(0, 0xD2047988)

    local rot = GetCamRot(cam, 2)
    
    local yValue = rAxisY * 5
    local newZ = rot.z + (rAxisX * -10)
    local newXval = rot.x - yValue

    if (newXval >= minY) and (newXval <= maxY) then
        newX = newXval
    end

    if newX and newZ then
        SetCamRot(cam, vector3(newX, rot.y, newZ), 2)
    end
end

--- Handle camera movement
local function Movement()
    local x, y, z = table.unpack(GetCamCoord(cam))
    local rot = GetCamRot(cam, 2)

    local dx = math.sin(-rot.z * math.pi / 180) * movementSpeed
    local dy = math.cos(-rot.z * math.pi / 180) * movementSpeed
    local dz = math.tan(rot.x * math.pi / 180) * movementSpeed

    local dx2 = math.sin(math.floor(rot.z + 90.0) % 360 * -1.0 * math.pi / 180) * movementSpeed
    local dy2 = math.cos(math.floor(rot.z + 90.0) % 360 * -1.0 * math.pi / 180) * movementSpeed

    local moveX = GetSmartControlNormal(U.Keys['A_D']) -- Left & Right
    local moveY = GetSmartControlNormal(U.Keys['W_S']) -- Forward & Backward
    local moveZ = GetSmartControlNormal({U.Keys['Q'], U.Keys['E']}) -- Up & Down

    if moveX ~= 0.0 then
        x = x - dx2 * moveX
        y = y - dy2 * moveX
    end

    if moveY ~= 0.0 then
        x = x - dx * moveY
        y = y - dy * moveY
    end

    if moveZ ~= 0.0 then
        z = z + dz * moveZ
    end

    if #(GetEntityCoords(PlayerPedId()) - vec3(x, y, z)) <= maxCamDistance and (not hookedFunc or hookedFunc(vec3(x, y, z))) then
        SetCamCoord(cam, x, y, z)
    end
end

--- Hanndle camera controls (movement & rotation)
local function CamControls()
    Rotations()
    Movement()
end

--- Setup Gizmo
--- @param entity number
--- @param cfg table | nil
--- @param allowPlace function | nil
--- @return table | nil
function ToggleGizmo(entity, cfg, allowPlace)
    if not entity then return end

    if gizmoActive then
        Init(false)
    end

    enableCam = (cfg?.EnableCam == nil and Config.EnableCam) or cfg.EnableCam
    maxDistance = (cfg?.MaxDistance == nil and Config.MaxDistance) or cfg.MaxDistance
    maxCamDistance = (cfg?.MaxCamDistance == nil and Config.MaxCamDistance) or cfg.MaxCamDistance
    minY = (cfg?.MinY == nil and Config.MinY) or cfg.MinY
    maxY = (cfg?.MaxY == nil and Config.MaxY) or cfg.MaxY
    movementSpeed = (cfg?.MovementSpeed == nil and Config.MovementSpeed) or cfg.MovementSpeed
    mode = 'translate'

    stored = {
        coords = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity)
    }

    hookedFunc = allowPlace

    SendNUIMessage({
        action = 'SetupGizmo',
        data = {
            handle = entity,
            position = stored.coords,
            rotation = stored.rotation,
            gizmoMode = mode
        }
    })

    Init(true)

    responseData = promise.new()

    CreateThread(function()
        while gizmoActive do
            Wait(0)
            SendNUIMessage({
                action = 'SetCameraPosition',
                data = {
                    position = GetFinalRenderedCamCoord(),
                    rotation = GetFinalRenderedCamRot(0)
                }
            })
        end
    end)

    CreateThread(function()
        while gizmoActive do
            Wait(0)
            DisableControlsAndUI()

            if cam then
                CamControls()
            end
        end
    end)

    CreateThread(function()
        local PromptGroup = U.Prompts:SetupPromptGroup()
        local TranslatePrompt = PromptGroup:RegisterPrompt(_('rotate'), U.Keys[Config.Keybinds.ToggleMode], 1, 1, true, 'click', {tab = 0})
        local SnapToGroundPrompt = PromptGroup:RegisterPrompt(_('Snap To Ground'), U.Keys[Config.Keybinds.SnapToGround], 1, 1, true, 'click', {tab = 0})
        local DonePrompt = PromptGroup:RegisterPrompt(_('Done Editing'), U.Keys[Config.Keybinds.Finish], 1, 1, true, 'click', {tab = 0})
        local CancelPrompt = PromptGroup:RegisterPrompt(_('Cancel'), U.Keys[Config.Keybinds.Cancel], 1, 1, true, 'click', {tab = 0})
        local LRPrompt = PromptGroup:RegisterPrompt(_('Move L/R'), U.Keys['A_D'], (cam and true or false), (cam and true or false), true, 'click', {tab = 0})
        local FBPrompt = PromptGroup:RegisterPrompt(_('Move F/B'), U.Keys['W_S'], (cam and true or false), (cam and true or false), true, 'click', {tab = 0})
        local UpPrompt = PromptGroup:RegisterPrompt(_('Move Up'), U.Keys['E'], (cam and true or false), (cam and true or false), true, 'click', {tab = 0})
        local DownPrompt = PromptGroup:RegisterPrompt(_('Move Down'), U.Keys['Q'], (cam and true or false), (cam and true or false), true, 'click', {tab = 0})

        while gizmoActive do
            Wait(5)
            PromptGroup:ShowGroup(_('Gizmo'))

            if TranslatePrompt:HasCompleted() then
                mode = (mode == 'translate' and 'rotate' or 'translate')
                SendNUIMessage({
                    action = 'SetGizmoMode',
                    data = mode
                })

                TranslatePrompt:PromptText(_U((mode == 'translate' and 'rotate' or 'translate')))
            end

            if SnapToGroundPrompt:HasCompleted() then
                PlaceObjectOnGroundProperly(entity)
                SendNUIMessage({
                    action = 'SetupGizmo',
                    data = {
                        handle = entity,
                        position = GetEntityCoords(entity),
                        rotation = GetEntityRotation(entity)
                    }
                })
            end

            if DonePrompt:HasCompleted() then
                local coords = GetEntityCoords(entity)
                responseData:resolve({
                    entity = entity,
                    coords = coords,
                    position = coords, -- Alias
                    rotation = GetEntityRotation(entity)
                })

                Init(false)
            end

            if CancelPrompt:HasCompleted() then

                responseData:resolve({
                    canceled = true,
                    entity = entity,
                    coords = stored.coords,
                    position = stored.coords, -- Alias
                    rotation = stored.rotation
                })

                SetEntityCoordsNoOffset(entity, stored.coords.x, stored.coords.y, stored.coords.z)
                SetEntityRotation(entity, stored.rotation.x, stored.rotation.y, stored.rotation.z)

                Init(false)

            end
        end

        TranslatePrompt:DeletePrompt()
        SnapToGroundPrompt:DeletePrompt()
        DonePrompt:DeletePrompt()
        LRPrompt:DeletePrompt()
        FBPrompt:DeletePrompt()
        UpPrompt:DeletePrompt()
        DownPrompt:DeletePrompt()
    end)

    return Citizen.Await(responseData)
end

--- Register NUI Callback for updating entity position and rotation
--- @param data table
--- @param cb function
RegisterNUICallback('UpdateEntity', function(data, cb)
    local entity = data.handle
    local position = data.position
    local rotation = data.rotation

    if (maxDistance and #(vec3(position.x, position.y, position.z) - stored.coords) <= maxDistance) and (not hookedFunc or hookedFunc(position)) then
        SetEntityCoordsNoOffset(entity, position.x, position.y, position.z)
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)
        return cb({status = 'ok'})
    end

    position = GetEntityCoords(entity)
    rotation = GetEntityRotation(entity)

    cb({
        status = 'Distance is too far',
        position = {x = position.x, y = position.y, z = position.z},
        rotation = {x = rotation.x, y = rotation.y, z = rotation.z}
    })
end)

--- If DevMode is enabled, register a command to spawn a crate for testing
if Config.DevMode then
RegisterCommand('gizmo', function()
    RequestModel('p_crate14x')

    while not HasModelLoaded('p_crate14x') do
        Wait(100)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local offset = coords + (forward * 3)
    local entity = CreateObject(joaat('p_crate14x'), offset.x, offset.y, offset.z, true, true, true)

    while not DoesEntityExist(entity) do 
        Wait(100) 
    end

    local data = ToggleGizmo(entity)

    print(json.encode(data, {indent = true}))

    if entity then
        DeleteEntity(entity)
    end
end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == U.Cache.Resource then
        Init(false)
    end
end)

--- Export ToggleGizmo function
--- @usage exports.gs_gizmo:Toggle(entity, {}, function(position) return true end)
exports('Toggle', ToggleGizmo)

--- Export Handler for https://github.com/outsider31000/object_gizmo/tree/main
ExportHandler('object_gizmo', 'useGizmo', ToggleGizmo)