local QBCore = exports['qb-core']:GetCoreObject()
lib.locale()

local currentShop = nil

local blips = {}


local function comma_value(amount)
    local formatted = amount
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

function CreateVehicleMenuForCategory(category, netId, selected)
    local category = category
    local vehicles = QBCore.Shared.Vehicles
    local options = {}

    for k, v in pairs(vehicles) do
        if vehicles[k]['category'] == category then
            if vehicles[k]["shop"] == currentShop then
                options[#options + 1] = {
                    title = v.name,
                    icon = 'fa-solid fa-car',
                    disabled = v.model == selected,
                    description = locale('price', comma_value(v.price)),
                    onSelect = function()
                        TriggerServerEvent('qw_dealerships:server:swapVehicles', currentShop, v.model, netId)
                    end
                }
            end
        end
    end

    lib.registerContext({
        id = 'veh_category_list',
        title = category,
        options = options
    })

    lib.showContext('veh_category_list')
end

RegisterNetEvent('qw_dealerships:client:openPurchaseMenu', function(data)
    local model = data.model
    local vehicleType = data.vehicleType
    local vehicle = QBCore.Shared.Vehicles[model]
    local options = {
        {
            title = locale('purchase_vehicle'),
            icon = 'fa-solid fa-car',
            description = locale('price', comma_value(vehicle.price)),
            onSelect = function()
                TriggerServerEvent('qw_dealerships:server:purchaseFreeUse', model, vehicleType)
            end
        },
        {
            title = locale('test_drive_label'),
            icon = 'fa-solid fa-car',
            description = locale('test_drive_description'),
            onSelect = function()
                print('Test Drive')
            end
        },

    }

    lib.registerContext({
        id = 'veh_purchase_menu',
        title = vehicle.name,
        options = options
    })

    lib.showContext('veh_purchase_menu')
end)

RegisterNetEvent('qw_dealerships:client:vehiclePurchased', function(model, plate, vehicleType)
    lib.notify({
        title = locale('dealership_notification_title'),
        description = locale('vehicle_purchased', model),
        type = 'success'
    })

    TriggerServerEvent('qw_dealerships:server:spawnNewlyPurchased', model, plate, currentShop, vehicleType)
end)

RegisterNetEvent('qw_dealerships:client:finishPurchase', function(netId, plate)
    local veh = NetToVeh(netId)
    local player = cache.ped

    SetVehicleNumberPlateText(veh, plate)
    SetVehicleOnGroundProperly(veh)

    exports[Config.FuelExport]:SetFuel(veh, 100.0)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
    TaskWarpPedIntoVehicle(player, veh, -1)
end)

RegisterNetEvent('qw_dealerships:client:openVehicleMenu', function(data)
    local categories = data.categories
    local netId = data.netId
    local selected = data.selected
    local options = {}

    for k, v in pairs(categories) do
        options[#options + 1] = {
            title = v,
            icon = 'fa-solid fa-car',
            arrow = true,
            onSelect = function()
                CreateVehicleMenuForCategory(k, netId, selected)
            end
        }
    end

    lib.registerContext({
        id = 'veh_interaction_menu',
        title = locale('vehicle_interaction'),
        options = options
    })

    lib.showContext('veh_interaction_menu')
end)

RegisterNetEvent('qw_dealerships:client:noMoney', function()
    lib.notify({
        title = locale('dealership_notification_title'),
        description = locale('not_enough_money'),
        type = 'error'
    })
end)


AddStateBagChangeHandler('shopVehicle', nil, function(bagName, key, value)
    local ent = GetEntityFromStateBagName(bagName)
    if ent == 0 then return end

    PlaceObjectOnGroundProperly(ent)
    SetEntityInvincible(ent, true)
    SetVehicleDirtLevel(ent, 0.0)
    SetVehicleDoorsLocked(ent, 3)
    FreezeEntityPosition(ent, true)
    SetVehicleNumberPlateText(ent, 'BUY ME')

    exports.ox_target:removeEntity(value.netId,
        { 'dealerships:veh-interaction', 'dealerships:sell-veh', 'dealerships:pruchase-selected' })

    exports.ox_target:addEntity(value.netId, {
        {
            name = 'dealerships:veh-interaction',
            event = 'qw_dealerships:client:openVehicleMenu',
            categories = value.categories,
            netId = value.netId,
            selected = value.selected,
            icon = 'fa-solid fa-car',
            label = locale('vehicle_interaction'),
            canInteract = function(_, distance)
                return distance < 2.0 and value.isFreeUse or
                    distance < 2.0 and not value.isFreeUse and
                    QBCore.Functions.GetPlayerData().job.name == Config.Shops[currentShop].job
            end
        },
        {
            name = 'dealerships:pruchase-selected',
            event = 'qw_dealerships:client:openPurchaseMenu',
            model = value.selected,
            vehicleType = value.vehicleType,
            icon = 'fa-solid fa-car',
            label = locale('pur_test_drive'),
            canInteract = function(_, distance)
                return distance < 2.0 and value.isFreeUse
            end
        },
        {
            name = 'dealerships:sell-veh',
            event = 'qw_dealerships:client:sellCurrent',
            selected = value.selected,
            icon = 'fa-solid fa-car',
            label = locale('sell_current'),
            canInteract = function(_, distance)
                return distance < 2.0 and not value.isFreeUse and
                    QBCore.Functions.GetPlayerData().job.name == Config.Shops[currentShop].job
            end
        }
    })
end)

AddStateBagChangeHandler('purchasedVehicle', nil, function(bagName, _, value)
    if not value.purchaser then return end
    if value.purchaser ~= cache.serverId then return end

    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 then
        return print(('received invalid entity from statebag! (%s)'):format(bagName))
    end

    while not DoesEntityExist(entity) do
        Wait(0)
    end

    if NetworkGetEntityOwner(entity) == cache.playerId then
        -- Do code
        TriggerEvent('qw_dealerships:client:finishPurchase', value.netId, value.plate)
    else
        NetworkRequestControlOfEntity(entity)

        while not NetworkHasControlOfEntity(entity) do
            Wait(0)
        end

        -- Do Code
        TriggerEvent('qw_dealerships:client:finishPurchase', value.netId, value.plate)
    end
end)

local zones = {}

local function createShopZones()
    for k, v in pairs(Config.Shops) do
        zones[#zones + 1] = lib.zones.poly({
                points = v.shopZone,
                onEnter = function()
                    currentShop = k
                end,
                onExit = function()
                    currentShop = nil
                end,
                inside = function()
                    currentShop = k
                end,
                debug = v.debugZone
            })
    end
end

local function deleteShopZones()
    for i = 1, #zones do
        zones[i]:remove()
    end
end

local function createBlips()
    for k, v in pairs(Config.Shops) do
        if v.showBlip then
            local blip = AddBlipForCoord(v['blipLocation'].x, v['blipLocation'].y, v['blipLocation'].z)
            SetBlipSprite(blip, v['blipSprite'])
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, v['blipColor'])
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v['blipLabel'])
            EndTextCommandSetBlipName(blip)

            blips[#blips + 1] = blip
        end
    end
end

local function deleteBlips()
    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(100)
    createShopZones()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deleteShopZones()
    deleteBlips()
end)


AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        createShopZones()
        createBlips()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        deleteShopZones()
        deleteBlips()
    end
end)
