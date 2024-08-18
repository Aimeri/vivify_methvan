local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('vivify_methvan:server:removeCurrency')
AddEventHandler('vivify_methvan:server:removeCurrency', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem(Config.Currency, amount) then
        TriggerClientEvent('QBCore:Notify', src, Config.CurrencyLabel .. ' removed and vehicle spawned!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to remove ' .. Config.Currency .. '!', 'error')
    end
end)

RegisterNetEvent('vivify_methvan:server:returnVehicle')
AddEventHandler('vivify_methvan:server:returnVehicle', function(refundAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.AddItem(Config.Currency, refundAmount)
        TriggerClientEvent('QBCore:Notify', src, 'You have been refunded ' .. refundAmount .. ' ' .. Config.CurrencyLabel .. '!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Unable to process refund!', 'error')
    end
end)

RegisterNetEvent('vivify_methvan:server:processMeth')
AddEventHandler('vivify_methvan:server:processMeth', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local canProduce = true
    for _, ingredient in ipairs(Config.Ingredients) do
        if not Player.Functions.GetItemByName(ingredient.name) or Player.Functions.GetItemByName(ingredient.name).amount < ingredient.amount then
            canProduce = false
            break
        end
    end

    if canProduce then
        for _, ingredient in ipairs(Config.Ingredients) do
            Player.Functions.RemoveItem(ingredient.name, ingredient.amount)
        end
        Player.Functions.AddItem('meth', 1)
        TriggerClientEvent('QBCore:Notify', src, 'Meth produced successfully!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have enough ingredients to produce meth!', 'error')
    end
end)