local openInventory = {}

RegisterServerEvent('voidrp-inventoryhud:openInventory')
AddEventHandler('voidrp-inventoryhud:openInventory', function(inventory)
    if openInventory[inventory.owner] == nil then
        openInventory[inventory.owner] = {}
    end
    openInventory[inventory.owner][source] = true
end)

RegisterServerEvent('voidrp-inventoryhud:closeInventory')
AddEventHandler('voidrp-inventoryhud:closeInventory', function(inventory)
    if openInventory[inventory.owner] == nil then
        openInventory[inventory.owner] = {}
    end
    if openInventory[inventory.owner][source] then
        openInventory[inventory.owner][source] = nil
    end
end)

RegisterServerEvent('voidrp-inventoryhud:refreshInventory')
AddEventHandler('voidrp-inventoryhud:refreshInventory', function(owner)
    if openInventory[owner] == nil then
        openInventory[owner] = {}
    end

    for k, v in pairs(openInventory[owner]) do
        TriggerClientEvent('voidrp-inventoryhud:refreshInventory', k)
    end
end)

RegisterServerEvent("voidrp-inventoryhud:MoveToEmpty")
AddEventHandler("voidrp-inventoryhud:MoveToEmpty", function(data)
    local source = source
    handleWeaponRemoval(data, source)
    print(tostring(data.originSlot))
    print(tostring(data.destinationSlot))
    if data.originOwner == data.destinationOwner and data.originTier.name == data.destinationTier.name then
        local originInvHandler = InvType[data.originTier.name]
        originInvHandler.getInventory(data.originOwner, function(inventory)
            inventory[tostring(data.destinationSlot)] = inventory[tostring(data.originSlot)]
            inventory[tostring(data.originSlot)] = nil
            originInvHandler.saveInventory(data.originOwner, inventory)
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        end)
    else
        local originInvHandler = InvType[data.originTier.name]
        local destinationInvHandler = InvType[data.destinationTier.name]
        if data.originTier.name == 'shop' then
            local player = ESX.GetPlayerFromIdentifier(data.destinationOwner)
            if player.getMoney() >= data.originItem.price * data.originItem.qty then
                player.removeMoney(data.originItem.price * data.originItem.qty)
            else
                TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
                TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
                return
            end
        end

        if data.destinationTier.name == 'shop' then
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
            print('Attempt to sell')
            return
        end

        originInvHandler.getInventory(data.originOwner, function(originInventory)
            destinationInvHandler.getInventory(data.destinationOwner, function(destinationInventory)

                destinationInventory[tostring(data.destinationSlot)] = originInventory[tostring(data.originSlot)]
                originInventory[tostring(data.originSlot)] = nil
                destinationInvHandler.saveInventory(data.destinationOwner, destinationInventory)
                originInvHandler.saveInventory(data.originOwner, originInventory)

                if data.originTier.name == 'player' then
                    data.originItem.block = true
                    local ownerPlayer = ESX.GetPlayerFromIdentifier(data.originOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.originItem, data.originItem.qty, ownerPlayer.source)
                    ownerPlayer.removeInventoryItem(data.originItem.id, data.originItem.qty)
                end

                if data.destinationTier.name == 'player' then
                    data.originItem.block = true
                    local destinationPlayer = ESX.GetPlayerFromIdentifier(data.destinationOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.originItem, data.originItem.qty, destinationPlayer.source)
                    destinationPlayer.addInventoryItem(data.originItem.id, data.originItem.qty)
                end
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
            end)
        end)
    end
end)

RegisterServerEvent("voidrp-inventoryhud:SwapItems")
AddEventHandler("voidrp-inventoryhud:SwapItems", function(data)
    local source = source

    handleWeaponRemoval(data, source)
    if data.originTier.name == 'shop' then
        print('Attempt to Swap in Store')
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
        return
    end

    if data.destinationTier.name == 'shop' then
        print('Attempt to Swap in Store')
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
        return
    end

    if data.originOwner == data.destinationOwner and data.originTier.name == data.destinationTier.name then
        local originInvHandler = InvType[data.originTier.name]
        originInvHandler.getInventory(data.originOwner, function(inventory)
            local tempItem = inventory[tostring(data.originSlot)]
            inventory[tostring(data.originSlot)] = inventory[tostring(data.destinationSlot)]
            inventory[tostring(data.destinationSlot)] = tempItem
            originInvHandler.saveInventory(data.originOwner, inventory)
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        end)
    else
        local originInvHandler = InvType[data.originTier.name]
        local destinationInvHandler = InvType[data.destinationTier.name]
        originInvHandler.getInventory(data.originOwner, function(originInventory)
            destinationInvHandler.getInventory(data.destinationOwner, function(destinationInventory)
                local tempItem = originInventory[tostring(data.originSlot)]
                originInventory[tostring(data.originSlot)] = destinationInventory[tostring(data.destinationSlot)]
                destinationInventory[tostring(data.destinationSlot)] = tempItem
                originInvHandler.saveInventory(data.originOwner, originInventory)
                destinationInvHandler.saveInventory(data.destinationOwner, destinationInventory)

                if data.originTier.name == 'player' then
                    data.originItem.block = true
                    data.destinationItem.block = true
                    local originPlayer = ESX.GetPlayerFromIdentifier(data.originOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.originItem, data.originItem.qty, originPlayer.source)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.destinationItem, data.destinationItem.qty, originPlayer.source)
                    originPlayer.addInventoryItem(data.originItem.id, data.originItem.qty)
                    originPlayer.removeInventoryItem(data.destinationItem.id, data.destinationItem.qty)
                end

                if data.destinationTier.name == 'player' then
                    data.originItem.block = true
                    data.destinationItem.block = true
                    local destinationPlayer = ESX.GetPlayerFromIdentifier(data.destinationOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.originItem, data.originItem.qty, destinationPlayer.source)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.destinationItem, data.destinationItem.qty, destinationPlayer.source)
                    destinationPlayer.removeInventoryItem(data.originItem.id, data.originItem.qty)
                    destinationPlayer.addInventoryItem(data.destinationItem.id, data.destinationItem.qty)
                end

                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
            end)
        end)
    end
end)

RegisterServerEvent("voidrp-inventoryhud:CombineStack")
AddEventHandler("voidrp-inventoryhud:CombineStack", function(data)
    local source = source

    handleWeaponRemoval(data, source)
    if data.originTier.name == 'shop' then
        local player = ESX.GetPlayerFromIdentifier(data.destinationOwner)
        if player.getMoney() >= data.originItem.price * data.originQty then
            player.removeMoney(data.originItem.price * data.originQty)
        else
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
            return
        end
    end

    if data.destinationTier.name == 'shop' then
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
        print('Attempt to sell')
        return
    end

    if data.originOwner == data.destinationOwner and data.originTier.name == data.destinationTier.name then
        local originInvHandler = InvType[data.originTier.name]
        originInvHandler.getInventory(data.originOwner, function(inventory)
            inventory[tostring(data.originSlot)] = nil
            inventory[tostring(data.destinationSlot)].count = data.destinationQty
            originInvHandler.saveInventory(data.originOwner, inventory)
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        end)
    else
        local originInvHandler = InvType[data.originTier.name]
        local destinationInvHandler = InvType[data.destinationTier.name]
        originInvHandler.getInventory(data.originOwner, function(originInventory)
            destinationInvHandler.getInventory(data.destinationOwner, function(destinationInventory)
                originInventory[tostring(data.originSlot)] = nil
                destinationInventory[tostring(data.destinationSlot)].count = data.destinationQty
                originInvHandler.saveInventory(data.originOwner, originInventory)
                destinationInvHandler.saveInventory(data.destinationOwner, destinationInventory)

                if data.originTier.name == 'player' then
                    data.originItem.block = true
                    local originPlayer = ESX.GetPlayerFromIdentifier(data.originOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.originItem, data.originItem.qty, originPlayer.source)
                    originPlayer.removeInventoryItem(data.originItem.id, data.originItem.qty)
                end

                if data.destinationTier.name == 'player' then
                    data.originItem.block = true
                    local destinationPlayer = ESX.GetPlayerFromIdentifier(data.destinationOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.originItem, data.originItem.qty, destinationPlayer.source)
                    destinationPlayer.addInventoryItem(data.originItem.id, data.originItem.qty)
                end

                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
            end)
        end)
    end
end)

RegisterServerEvent("voidrp-inventoryhud:EmptySplitStack")
AddEventHandler("voidrp-inventoryhud:EmptySplitStack", function(data)

    handleWeaponRemoval(data, source)
    if data.originTier.name == 'shop' then
        local player = ESX.GetPlayerFromIdentifier(data.destinationOwner)
        if player.getMoney() >= data.originItem.price * data.moveQty then
            player.removeMoney(data.originItem.price * data.moveQty)
        else
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
            return
        end
    end

    if data.destinationTier.name == 'shop' then
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
        print('Attempt to sell')
        return
    end

    local source = source
    if data.originOwner == data.destinationOwner and data.originTier.name == data.destinationTier.name then
        local originInvHandler = InvType[data.originTier.name]
        originInvHandler.getInventory(data.originOwner, function(inventory)
            inventory[tostring(data.originSlot)].count = inventory[tostring(data.originSlot)].count - data.moveQty
            local item = inventory[tostring(data.originSlot)]
            inventory[tostring(data.destinationSlot)] = {
                name = item.name,
                count = data.moveQty
            }
            originInvHandler.saveInventory(data.originOwner, inventory)
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        end)
    else
        local originInvHandler = InvType[data.originTier.name]
        local destinationInvHandler = InvType[data.destinationTier.name]
        originInvHandler.getInventory(data.originOwner, function(originInventory)
            destinationInvHandler.getInventory(data.destinationOwner, function(destinationInventory)
                originInventory[tostring(data.originSlot)].count = originInventory[tostring(data.originSlot)].count - data.moveQty
                local item = originInventory[tostring(data.originSlot)]
                destinationInventory[tostring(data.destinationSlot)] = {
                    name = item.name,
                    count = data.moveQty
                }
                originInvHandler.saveInventory(data.originOwner, originInventory)
                destinationInvHandler.saveInventory(data.destinationOwner, destinationInventory)

                if data.originTier.name == 'player' then
                    local originPlayer = ESX.GetPlayerFromIdentifier(data.originOwner)
                    data.originItem.block = true
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.originItem, data.moveQty, originPlayer.source)
                    originPlayer.removeInventoryItem(data.originItem.id, data.moveQty)
                end

                if data.destinationTier.name == 'player' then
                    local destinationPlayer = ESX.GetPlayerFromIdentifier(data.destinationOwner)
                    data.originItem.block = true
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.originItem, data.moveQty, destinationPlayer.source)
                    destinationPlayer.addInventoryItem(data.originItem.id, data.moveQty)
                end
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
            end)
        end)
    end
end)

RegisterServerEvent("voidrp-inventoryhud:SplitStack")
AddEventHandler("voidrp-inventoryhud:SplitStack", function(data)
    local source = source
    handleWeaponRemoval(data, source)

    if data.originTier.name == 'shop' then
        local player = ESX.GetPlayerFromIdentifier(data.destinationOwner)
        if player.getMoney() >= data.originItem.price * data.moveQty then
            player.removeMoney(data.originItem.price * data.moveQty)
        else
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
            return
        end
    end

    if data.destinationTier.name == 'shop' then
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
        print('Attempt to sell')
        return
    end

    if data.originOwner == data.destinationOwner and data.originTier.name == data.destinationTier.name then
        local originInvHandler = InvType[data.originTier.name]
        originInvHandler.getInventory(data.originOwner, function(inventory)
            inventory[tostring(data.originSlot)].count = inventory[tostring(data.originSlot)].count - data.moveQty
            inventory[tostring(data.destinationSlot)].count = inventory[tostring(data.destinationSlot)].count + data.moveQty
            originInvHandler.saveInventory(data.originOwner, inventory)
            TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
        end)
    else
        local originInvHandler = InvType[data.originTier.name]
        local destinationInvHandler = InvType[data.destinationTier.name]
        originInvHandler.getInventory(data.originOwner, function(originInventory)
            destinationInvHandler.getInventory(data.destinationOwner, function(destinationInventory)
                originInventory[tostring(data.originSlot)].count = originInventory[tostring(data.originSlot)].count - data.moveQty
                destinationInventory[tostring(data.destinationSlot)].count = destinationInventory[tostring(data.destinationSlot)].count + data.moveQty
                originInvHandler.saveInventory(data.originOwner, originInventory)
                destinationInvHandler.saveInventory(data.destinationOwner, destinationInventory)

                if data.originTier.name == 'player' then
                    data.originItem.block = true
                    local originPlayer = ESX.GetPlayerFromIdentifier(data.originOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.originItem, data.moveQty, originPlayer.source)
                    originPlayer.removeInventoryItem(data.originItem.id, data.moveQty)
                end

                if data.destinationTier.name == 'player' then
                    data.originItem.block = true
                    local destinationPlayer = ESX.GetPlayerFromIdentifier(data.destinationOwner)
                    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.originItem, data.moveQty, destinationPlayer.source)
                    destinationPlayer.addInventoryItem(data.originItem.id, data.moveQty)
                end
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.originOwner)
                TriggerEvent('voidrp-inventoryhud:refreshInventory', data.destinationOwner)
            end)
        end)
    end
end)

RegisterServerEvent("voidrp-inventoryhud:GiveItem")
AddEventHandler("voidrp-inventoryhud:GiveItem", function(data)
    handleWeaponRemoval(data, source)
    TriggerEvent('voidrp-inventoryhud:notifyImpendingRemoval', data.item, data.count, source)
    TriggerEvent('voidrp-inventoryhud:notifyImpendingAddition', data.item, data.count, data.target)
    local targetPlayer = ESX.GetPlayerFromId(data.target)
    targetPlayer.addInventoryItem(data.item.id, data.count)
    local sourcePlayer = ESX.GetPlayerFromId(source)
    sourcePlayer.removeInventoryItem(data.item.id, data.count)
    TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
    TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
end)

RegisterServerEvent("voidrp-inventoryhud:GiveCash")
AddEventHandler("voidrp-inventoryhud:GiveCash", function(data)
    local sourcePlayer = ESX.GetPlayerFromId(source)
    print(data.item)
    if data.item == 'cash' then

        if sourcePlayer.getMoney() >= data.count then
            sourcePlayer.removeMoney(data.count)
            local targetPlayer = ESX.GetPlayerFromId(data.target)
            targetPlayer.addMoney(data.count)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
        end

    elseif data.item == 'black_money' then
        if sourcePlayer.getAccount('black_money').money >= data.count then
            sourcePlayer.removeAccountMoney('black_money', data.count)
            local targetPlayer = ESX.GetPlayerFromId(data.target)
            targetPlayer.addAccountMoney('black_money', data.count)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', source)
            TriggerClientEvent('voidrp-inventoryhud:refreshInventory', data.target)
        end
    end
end)

function debugData(data)
    for k, v in pairs(data) do
        print(k .. ' ' .. v)
    end
end

function removeItemFromSlot(inventory, slot, count)
    if inventory[tostring(slot)].count - count > 0 then
        inventory[tostring(slot)].count = inventory[tostring(slot)].count - count
        return
    else
        inventory[tostring(slot)] = nil
        return
    end
end

function removeItemFromInventory(item, count, inventory)
    for k, v in pairs(inventory) do
        if v.name == item.name then
            if v.count - count < 0 then
                local tempCount = inventory[k].count
                inventory[k] = nil
                count = count - tempCount
            elseif v.count - count > 0 then
                inventory[k].count = inventory[k].count - count
                return
            elseif v.count - count == 0 then
                inventory[k] = nil
                return
            else
                print('Missing Remove condition')
            end
        end
    end
end

function addToInventory(item, type, inventory, max)
    if max == -1 then
        max = 9999
    end
    local toAdd = item.count
    while toAdd > 0 do
        toAdd = AttemptMerge(item, inventory, toAdd, max)
        if toAdd > 0 then
            toAdd = AddToEmpty(item, type, inventory, toAdd, max)
        else
            toAdd = 0
        end
    end
end

function AttemptMerge(item, inventory, count)
    local max = getItemDataProperty(item.name, 'max') or 100
    for k, v in pairs(inventory) do
        if v.name == item.name then
            if v.count + count > max then
                local tempCount = max - inventory[k].count
                inventory[tostring(k)].count = max
                count = count - tempCount
            elseif v.count + count <= max then
                inventory[tostring(k)].count = v.count + count
                return 0
            else
                print('Missing MERGE condition')
            end
        end
    end
    return count
end


function AddToEmpty(item, type, inventory, count)
    local max = getItemDataProperty(item.name, 'max') or 100
    for i = 1, InvType[type].slots, 1 do
        if inventory[tostring(i)] == nil then
            if count > max then
                inventory[tostring(i)] = item
                inventory[tostring(i)].count = max
                return count - max
            else
                inventory[tostring(i)] = item
                return 0
            end
        end
    end
    print('Inventory Overflow!')
    return 0
end

function createDisplayItem(item, esxItem, slot, price, type)
    local max = esxItem.limit
    if max == -1 then
        max = 9999
    end
    return {
        id = esxItem.name,
        itemId = esxItem.name,
        qty = item.count,
        slot = slot,
        label = esxItem.label,
        type = type or 'item',
        max = max,
        stackable = true,
        unique = esxItem.rare,
        usable = esxItem.usable,
        description = getItemDataProperty(esxItem.name, 'description'),
        weight = getItemDataProperty(esxItem.name, 'weight'),
        metadata = {},
        staticMeta = {},
        canRemove = esxItem.canRemove,
        price = price or 0,
        needs = false,
        closeUi = getItemDataProperty(esxItem.name, 'closeonuse'),
    }
end

function createItem(name, count)
    return { name = name, count = count }
end

ESX.RegisterServerCallback('voidrp-inventoryhud:getSecondaryInventory', function(source, cb, type, identifier)
    InvType[type].getDisplayInventory(identifier, cb, source)
end)

function saveInventory(identifier, type, data)
    MySQL.Async.execute('UPDATE voidrp_inventory SET data = @data WHERE owner = @owner AND type = @type', {
        ['@owner'] = identifier,
        ['@type'] = type,
        ['@data'] = json.encode(data)
    }, function(result)
        if result == 0 then
            createInventory(identifier, type, data)
        end
        TriggerEvent('voidrp-inventoryhud:savedInventory', identifier, type, data)
    end)
end

function createInventory(identifier, type, data)
    MySQL.Async.execute('INSERT INTO voidrp_inventory (owner, type, data) VALUES (@owner, @type, @data)', {
        ['@owner'] = identifier,
        ['@type'] = type,
        ['@data'] = json.encode(data)
    }, function()
        TriggerEvent('voidrp-inventoryhud:createdInventory', identifier, type, data)
    end)
end

function deleteInventory(identifier, type)
    MySQL.Async.execute('DELETE FROM voidrp_inventory WHERE owner = @owner AND type = @type', {
        ['@owner'] = identifier,
        ['@type'] = type
    }, function()
        TriggerEvent('voidrp-inventoryhud:deletedInventory', identifier, type)
    end)
end

function getDisplayInventory(identifier, type, cb, source)
    local player = ESX.GetPlayerFromId(source)
    InvType[type].getInventory(identifier, function(inventory)
        local itemsObject = {}

        for k, v in pairs(inventory) do
            local esxItem = player.getInventoryItem(v.name)
            local item = createDisplayItem(v, esxItem, tonumber(k))
            item.usable = false
            table.insert(itemsObject, item)
        end

        local inv = {
            invId = identifier,
            invTier = InvType[type],
            inventory = itemsObject,
        }
        cb(inv)
    end)
end

function getInventory(identifier, type, cb)
    MySQL.Async.fetchAll('SELECT data FROM voidrp_inventory WHERE owner = @owner and type = @type', {
        ['@owner'] = identifier,
        ['@type'] = type
    }, function(result)
        if #result == 0 then
            cb({})
            return
        end
        cb(json.decode(result[1].data))
        TriggerEvent('voidrp-inventoryhud:gotInventory', identifier, type, result[1].data)
    end)
end

function handleWeaponRemoval(data, source)
    if isWeapon(data.originItem.id) then
        if data.originOwner == data.destinationOwner and data.originTier.name == data.destinationTier.name then
            if data.destinationSlot > 5 then
                TriggerClientEvent('voidrp-inventoryhud:removeCurrentWeapon', source)
            end
        else
            TriggerClientEvent('voidrp-inventoryhud:removeCurrentWeapon', source)
        end
    end
end
