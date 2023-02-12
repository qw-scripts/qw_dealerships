local QBCore = exports['qb-core']:GetCoreObject()
local shops = {}
lib.locale()

local function spawnDealershipVehicles()
    for k, v in pairs(Config.Shops) do
        local isFreeUse = v.isFreeUse
        for i = 1, #v.vehicles do
            local veh = v.vehicles[i]
            local shopName = k
            TriggerEvent('qw_dealerships:server:spawnVehicle', shopName, veh, isFreeUse)
        end
    end
end

RegisterNetEvent('qw_dealerships:server:spawnVehicle', function(shopName, veh, isFreeUse)

    local model = veh.default
    local coords = veh.coords
    local vehicleType = veh.vehicleType
    local hash = joaat(model)

    if shops[shopName] == nil then
        shops[shopName] = {}
    end

    local vehicle = CreateVehicleServerSetter(hash, vehicleType, coords.x, coords.y, coords.z, coords.w)

    local Checks = 0

    while not DoesEntityExist(vehicle) do
        if Checks == 10 then break end
        Wait(25)
        Checks += 1
    end

    if DoesEntityExist(vehicle) then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)

        Entity(vehicle).state.shopVehicle = {
            categories = veh.categories,
            selected = veh.selected,
            coords = veh.coords,
            vehType = veh.vehicleType,
            isFreeUse = isFreeUse,
            netId = netId,
        }

        shops[shopName][#shops[shopName]+1] = {
            categories = veh.categories,
            selected = veh.selected,
            isFreeUse = isFreeUse,
            netId = netId,
        }
    end
end)

local function deleteVehicleForSwap(shopName, netId)

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end

    if shops[shopName] == nil then
        shops[shopName] = {}
    end

    local temp = {}
    for i = 1, #shops[shopName] do
        if shops[shopName][i].netId ~= netId then
            temp[#temp+1] = shops[shopName][i]
        end
    end

    shops[shopName] = temp
end

RegisterNetEvent('qw_dealerships:server:swapVehicles', function(shopName, to, netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    local src = source

    local selectedVeh = Entity(veh).state.shopVehicle

    if selectedVeh ~= nil then
        local coords = selectedVeh.coords
        local vehicleType = selectedVeh.vehType
        local categories = selectedVeh.categories
        local isFreeUse = selectedVeh.isFreeUse

        local hash = joaat(to)

        deleteVehicleForSwap(shopName, netId)
        Wait(300)
        local vehicle = CreateVehicleServerSetter(hash, vehicleType, coords.x, coords.y, coords.z, coords.w)

        local Checks = 0

        while not DoesEntityExist(vehicle) do
            if Checks == 10 then break end
            Wait(25)
            Checks += 1
        end

        if DoesEntityExist(vehicle) then
            local netID = NetworkGetNetworkIdFromEntity(vehicle)

            Entity(vehicle).state.shopVehicle = {
                categories = categories,
                selected = to,
                coords = coords,
                vehType = vehicleType,
                isFreeUse = isFreeUse,
                netId = netID,
            }

            shops[shopName][#shops[shopName]+1] = {
                categories = categories,
                selected = to,
                isFreeUse = isFreeUse,
                netId = netID,
            }

            Wait(300)
            TriggerClientEvent('qw_dealerships:client:openPurchaseMenu', src, { model = to, vehicleType = vehicleType })
        else
            print('Vehicle does not exist')
        end
    end
end)

local function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

RegisterNetEvent('qw_dealerships:server:purchaseFreeUse', function(model, vehicleType)
    local src = source
    local vehicle = QBCore.Shared.Vehicles[model]
    local pData = QBCore.Functions.GetPlayer(src)

    if not pData then return end

    local cid = pData.PlayerData.citizenid
    local cash = pData.PlayerData.money['cash']
    local bank = pData.PlayerData.money['bank']
    local vehiclePrice = vehicle['price']

    local plate = GeneratePlate()

    if cash > tonumber(vehiclePrice) then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            model,
            model,
            '{}',
            plate,
            'pillboxgarage',
            0
        })

        TriggerClientEvent('qw_dealerships:client:vehiclePurchased', src, model, plate, vehicleType)
        pData.Functions.RemoveMoney('cash', vehiclePrice, 'vehicle-bought-in-showroom')
    elseif bank > tonumber(vehiclePrice) then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            model,
            model,
            '{}',
            plate,
            'pillboxgarage',
            0
        })

        TriggerClientEvent('qw_dealerships:client:vehiclePurchased', src, model, plate, vehicleType)
        pData.Functions.RemoveMoney('bank', vehiclePrice, 'vehicle-bought-in-showroom')
    else
        TriggerClientEvent('qw_dealerships:client:noMoney', src)
    end
end)

RegisterNetEvent('qw_dealerships:server:spawnNewlyPurchased', function(model, plate, currentShop, vehicleType) 

    local model = model
    local coords = Config.Shops[currentShop].purchaseSpawn
    local vehicleType = vehicleType
    local hash = joaat(model)
    local src = source

    local vehicle = CreateVehicleServerSetter(hash, vehicleType, coords.x, coords.y, coords.z, coords.w)

    local Checks = 0

        while not DoesEntityExist(vehicle) do
            if Checks == 10 then break end
            Wait(25)
            Checks += 1
        end

        if DoesEntityExist(vehicle) then
            local netID = NetworkGetNetworkIdFromEntity(vehicle)
            
            Entity(vehicle).state.purchasedVehicle = {
                plate = plate,
                netId = netID,
                purchaser = src,
            }
        end
end)

AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
    spawnDealershipVehicles()
   end
end)

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
         for k, v in pairs(shops) do
              for i = 1, #v do
                local netId = v[i].netId
                local vehicle = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(vehicle) then
                     DeleteEntity(vehicle)
                end
              end
         end
   end
end)