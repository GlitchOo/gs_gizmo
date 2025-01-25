local gizmoActive, Cam = false, nil
local responseData = nil
local mode = 'translate'

local function Init(bool)
    local ped = PlayerPedId()
    if bool then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)

        if Config.EnableCam then
            local coords = GetGameplayCamCoord()
            local rot = GetGameplayCamRot(2)
            local fov = GetGameplayCamFov()

            Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

            SetCamCoord(Cam, coords.x, coords.y, coords.z + 0.5)
            SetCamRot(Cam, rot.x, rot.y, rot.z, 2)
            SetCamFov(Cam, fov)
            RenderScriptCams(true, true, 500, true, true)
            FreezeEntityPosition(ped, true)
        end
        
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(IsNuiFocusKeepingInput())
        FreezeEntityPosition(ped, false)

        if Cam then
            RenderScriptCams(false, true, 500, true, true)
            SetCamActive(Cam, false)
            DetachCam(Cam)
            DestroyCam(Cam, true)
            Cam = nil
        end
        
        SendNUIMessage({
            action = 'SetupGizmo',
            data = {
                handle = nil,
            }
        })
    end

    gizmoActive = bool
end

function DisableControlsAndUI()
    DisableControlAction(0, 0x07CE1E61, true)
    HideHudAndRadarThisFrame()
    DisablePlayerFiring(U.Cache.PlayerId, true)
end

local function GetSmartControlNormal(control)
    if type(control) == 'table' then
    local normal1 = GetDisabledControlNormal(0, control[1])
    local normal2 = GetDisabledControlNormal(0, control[2])
    return normal1 - normal2
    end

    return GetDisabledControlNormal(0, control)
end

local function Rotations()
    local newX
    local rAxisX = GetControlNormal(0, 0xA987235F)
    local rAxisY = GetControlNormal(0, 0xD2047988)

    local rot = GetCamRot(Cam, 2)
    
    local yValue = rAxisY * 5
    local newZ = rot.z + (rAxisX * -10)
    local newXval = rot.x - yValue

    if (newXval >= Config.MinY) and (newXval <= Config.MaxY) then
        newX = newXval
    end

    if newX and newZ then
        SetCamRot(Cam, vector3(newX, rot.y, newZ), 2)
    end
end

local function Movement()
    local x, y, z = table.unpack(GetCamCoord(Cam))
    local rot = GetCamRot(Cam, 2)

    local dx = math.sin(-rot.z * math.pi / 180) * Config.MovementSpeed
    local dy = math.cos(-rot.z * math.pi / 180) * Config.MovementSpeed
    local dz = math.tan(rot.x * math.pi / 180) * Config.MovementSpeed

    local dx2 = math.sin(math.floor(rot.z + 90.0) % 360 * -1.0 * math.pi / 180) * Config.MovementSpeed
    local dy2 = math.cos(math.floor(rot.z + 90.0) % 360 * -1.0 * math.pi / 180) * Config.MovementSpeed

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

    if #(GetEntityCoords(PlayerPedId()) - vector3(x, y, z)) <= Config.MaxDistance then
        SetCamCoord(Cam, x, y, z)
    end
end

local function CamControls()
    Rotations()
    Movement()
end

function ToggleGizmo(entity)
    if not entity then return end

    if gizmoActive then
        Init(false)
    end

    mode = 'translate'

    SendNUIMessage({
        action = 'SetupGizmo',
        data = {
            handle = entity,
            position = GetEntityCoords(entity),
            rotation = GetEntityRotation(entity),
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

            if Cam then
                CamControls()
            end
        end
    end)

    CreateThread(function()
        local PromptGroup = U.Prompts:SetupPromptGroup()
        local TranslatePrompt = PromptGroup:RegisterPrompt(_('rotate'), U.Keys[Config.Keybinds.ToggleMode], 1, 1, true, 'click', {tab = 0})
        local SnapToGroundPrompt = PromptGroup:RegisterPrompt(_('Snap To Ground'), U.Keys[Config.Keybinds.SnapToGround], 1, 1, true, 'click', {tab = 0})
        local DonePrompt = PromptGroup:RegisterPrompt(_('Done Editing'), U.Keys[Config.Keybinds.Finish], 1, 1, true, 'click', {tab = 0})
        local LRPrompt = PromptGroup:RegisterPrompt(_('Move L/R'), U.Keys['A_D'], (Cam and true or false), (Cam and true or false), true, 'click', {tab = 0})
        local FBPrompt = PromptGroup:RegisterPrompt(_('Move F/B'), U.Keys['W_S'], (Cam and true or false), (Cam and true or false), true, 'click', {tab = 0})
        local UpPrompt = PromptGroup:RegisterPrompt(_('Move Up'), U.Keys['E'], (Cam and true or false), (Cam and true or false), true, 'click', {tab = 0})
        local DownPrompt = PromptGroup:RegisterPrompt(_('Move Down'), U.Keys['Q'], (Cam and true or false), (Cam and true or false), true, 'click', {tab = 0})

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

                responseData:resolve({
                    entity = entity,
                    coords = GetEntityCoords(entity),
                    rotation = GetEntityRotation(entity)
                })

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

RegisterNUICallback('UpdateEntity', function(data, cb)
    local entity = data.handle
    local position = data.position
    local rotation = data.rotation

    SetEntityCoords(entity, position.x, position.y, position.z)
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)
    cb('ok')
end)

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

exports('Toggle', ToggleGizmo)