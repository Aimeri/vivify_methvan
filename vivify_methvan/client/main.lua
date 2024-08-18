local QBCore = exports['qb-core']:GetCoreObject()

local spawnedPeds = {}
local spawnedVehicle = nil

local function SpawnPeds()
    for i, location in ipairs(Config.PedLocation) do
        local pedModel = GetHashKey(Config.PedModel)

        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Citizen.Wait(0)
        end

        local ped = CreatePed(4, pedModel, location.x, location.y, location.z - 1, location.w, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        spawnedPeds[i] = ped
    end
end

local function CreateTargetZones()
    for i, location in ipairs(Config.PedLocation) do
        exports['qb-target']:AddTargetModel(Config.PedModel, {
            options = {
                {
                    event = 'vivify_methvan:client:borrowVan',
                    icon = 'fas fa-shuttle-van',
                    label = 'Borrow Van',
                },
                {
                    event = 'vivify_methvan:client:removeVehicle',
                    icon = 'fas fa-shuttle-van',
                    label = 'Return Van',
                },
            },
            distance = 2.5
        })
    end
end

local function CreateVehicleTarget()
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        exports['qb-target']:AddTargetEntity(spawnedVehicle, {
            options = {
                {
                    event = 'vivify_methvan:client:interactWithVan',
                    icon = 'fas fa-chair',
                    label = 'Sit In Back Seat',
                },
            },
            distance = 2.5
        })
    end
end

CreateThread(function()
    SpawnPeds()
end)

CreateThread(function()
    CreateTargetZones()
end)

CreateThread(function()
    CreateVehicleTarget()
end)

RegisterNetEvent('vivify_methvan:client:spawnVehicle')
AddEventHandler('vivify_methvan:client:spawnVehicle', function()
    local vehicleModel = 'journey'
    local vehicleSpawn = Config.CarSpawn

    local modelHash = GetHashKey(vehicleModel)
    if not IsModelValid(modelHash) or not IsModelInCdimage(modelHash) then
        return
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    spawnedVehicle = CreateVehicle(modelHash, vehicleSpawn.x, vehicleSpawn.y, vehicleSpawn.z, vehicleSpawn.w, true, false)
    SetEntityAsMissionEntity(spawnedVehicle, true, true)
    SetVehicleNumberPlateText(spawnedVehicle, "M3THV4N"..math.random(1,99))
    exports[Config.FuelResource]:SetFuel(spawnedVehicle, math.random(80, 100))

    SetModelAsNoLongerNeeded(modelHash)
    TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(spawnedVehicle))

    CreateVehicleTarget()
end)

RegisterNetEvent('vivify_methvan:client:removeVehicle')
AddEventHandler('vivify_methvan:client:removeVehicle', function()
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        local amountPaid = Config.CurrencyAmount
        local refundAmount = amountPaid * 0.5

        TriggerServerEvent('vivify_methvan:server:returnVehicle', refundAmount)

        DeleteVehicle(spawnedVehicle)
        TriggerEvent('QBCore:Notify', 'Vehicle returned.', 'success')
        spawnedVehicle = nil
    else
        TriggerEvent('QBCore:Notify', 'No vehicle found to return!', 'error')
    end
end)

RegisterNetEvent('vivify_methvan:client:borrowVan')
AddEventHandler('vivify_methvan:client:borrowVan', function()
    QBCore.Functions.GetPlayerData(function(playerData)
        local playerItems = playerData.items
        local currencyAmount = 0

        for _, item in ipairs(playerItems) do
            if item.name == Config.Currency then
                currencyAmount = item.amount
                break
            end
        end

        if currencyAmount >= Config.CurrencyAmount then
            TriggerServerEvent('vivify_methvan:server:removeCurrency', Config.CurrencyAmount)
            TriggerEvent('vivify_methvan:client:spawnVehicle')
        else
            TriggerEvent('QBCore:Notify', 'You do not have enough ' .. Config.CurrencyLabel .. '!', 'error')
        end
    end)
end)

RegisterNetEvent('vivify_methvan:client:interactWithVan')
AddEventHandler('vivify_methvan:client:interactWithVan', function()
    local playerPed = PlayerPedId()
    local seatIndex = 1

    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        exports['progressbar']:Progress({
            name = "entering_van",
            duration = 5000,
            label = "Sitting in van",
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            },
        }, function(cancelled)
            if not cancelled then
                TaskWarpPedIntoVehicle(playerPed, spawnedVehicle, seatIndex)
                TriggerEvent('vivify_methvan:client:OpenMenu')
            else
                TriggerEvent('QBCore:Notify', 'You could not sit in the back seat.', 'error')
            end
        end)
    end
end)



RegisterNetEvent('vivify_methvan:client:OpenMenu', function()
    local methMenu = {
        {
            header = 'Cook Meth',
            icon = 'fa-solid fa-circle-info',
            txt = 'Ingredients: Acetone, Lithium',
            params = {
                event = 'vivify_methvan:client:makeMeth',
            }
        },
        {
            header = "Close Menu",
            icon = 'fa-solid fa-circle-info',
            params = {
                event = 'vivify_methvan:client:closeMenu',
            }
        }
    }
    exports['qb-menu']:openMenu(methMenu)
end)

RegisterNetEvent('vivify_methvan:client:closeMenu')
AddEventHandler('vivify_methvan:client:closeMenu', function()
    exports['qb-menu']:closeMenu(methMenu)
end)

RegisterNetEvent('vivify_methvan:client:makeMeth')
AddEventHandler('vivify_methvan:client:makeMeth', function()
    local playerPed = PlayerPedId()
    local producingMeth = true

    local function hasIngredients()
        local playerData = QBCore.Functions.GetPlayerData()
        local hasAllIngredients = true

        for _, ingredient in ipairs(Config.Ingredients) do
            local itemFound = false
            for _, item in pairs(playerData.items) do
                if item.name == ingredient.name then
                    itemFound = true
                    if item.amount < ingredient.amount then
                        hasAllIngredients = false
                        break
                    end
                end
            end

            if not itemFound or not hasAllIngredients then
                return false
            end
        end

        return true
    end

    local function startMethProduction()
        producingMeth = true
        while producingMeth do
            exports['progressbar']:Progress({
                name = "meth_production",
                duration = Config.CraftTime,
                label = "Producing Meth",
                useWhileDead = false,
                canCancel = true,
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                },
            }, function(cancelled)
                if not cancelled then
                    TriggerServerEvent('vivify_methvan:server:processMeth')
                else
                    producingMeth = false
                end
            end)

            if not hasIngredients() then
                producingMeth = false
                TriggerEvent('QBCore:Notify', 'You do not have enough ingredients to continue!', 'error')
            end

            Citizen.Wait(0)
        end
        TriggerEvent('QBCore:Notify', 'Meth production stopped or completed.', 'success')
    end

    if hasIngredients() then
        startMethProduction()
    else
        TriggerEvent('QBCore:Notify', 'You do not have enough ingredients to start production!', 'error')
    end
end)
