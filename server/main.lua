QS = nil
TriggerEvent('qs-core:getSharedObject', function(library) QS = library end)

local playersHealing, deadPlayers = {}, {}

if GetResourceState("esx_phone") ~= 'missing' then
TriggerEvent('esx_phone:registerNumber', 'ambulance', TranslateCap('alert_ambulance'), true, true)
end

if GetResourceState("esx_society") ~= 'missing' then
TriggerEvent('esx_society:registerSociety', 'ambulance', 'Ambulance', 'society_ambulance', 'society_ambulance', 'society_ambulance', {type = 'public'})
end

RegisterNetEvent('esx_ambulancejob:status')
AddEventHandler('esx_ambulancejob:status', function(jobin, jobuit)
	local xPlayer = ESX.GetPlayerFromId(source)
    local grade = xPlayer.job.grade
	local jobin = 'ambulance'
	local jobuit = 'ambulanceuit'

		if xPlayer.job.name == ''..jobin..'' then
			xPlayer.setJob(''..jobuit..'', grade)
			TriggerClientEvent('qs-core:Notify', xPlayer.source, "Je bent uitgeklokt", "success")
		else
			if xPlayer.job.name == ''..jobuit..'' then
			xPlayer.setJob(''..jobin..'', grade)
			TriggerClientEvent('qs-core:Notify', xPlayer.source, "Je bent Ingeklokt", "success")
		end
	end
end)

RegisterNetEvent('esx_ambulancejob:revive')
AddEventHandler('esx_ambulancejob:revive', function(playerId)
	playerId = tonumber(playerId)
		local xPlayer = source and ESX.GetPlayerFromId(source)

		if xPlayer and xPlayer.job.name == 'ambulance' then
			local xTarget = ESX.GetPlayerFromId(playerId)
			if xTarget then
				if deadPlayers[playerId] then
					if Config.ReviveReward > 0 then
						xPlayer.showNotification(TranslateCap('revive_complete_award', xTarget.name, Config.ReviveReward))
						xPlayer.addMoney(Config.ReviveReward, "Revive Reward")
						xTarget.triggerEvent('esx_ambulancejob:revive')
					else
						xPlayer.showNotification(TranslateCap('revive_complete', xTarget.name))
						xTarget.triggerEvent('esx_ambulancejob:revive')
					end
					local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")

					for _, xPlayer in pairs(Ambulance) do
						if xPlayer.job.name == 'ambulance' then
							xPlayer.triggerEvent('esx_ambulancejob:PlayerNotDead', playerId)
						end
					end
					deadPlayers[playerId] = nil
				else
					xPlayer.showNotification(TranslateCap('player_not_unconscious'))
				end
			else
				xPlayer.showNotification(TranslateCap('revive_fail_offline'))
			end
		end
end)

AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
		return
	end
	if deadPlayers[eventData.id] then
		TriggerClientEvent('esx_ambulancejob:revive', eventData.id)
		local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")

		for _, xPlayer in pairs(Ambulance) do
			if xPlayer.job.name == 'ambulance' then
				xPlayer.triggerEvent('esx_ambulancejob:PlayerNotDead', eventData.id)
			end
		end
		deadPlayers[eventData.id] = nil
	end
end)

RegisterNetEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	local source = source
	deadPlayers[source] = 'dead'
	local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")

	for _, xPlayer in pairs(Ambulance) do
			xPlayer.triggerEvent('esx_ambulancejob:PlayerDead', source)
	end
end)

RegisterNetEvent('esx_ambulancejob:onPlayerDistress')
AddEventHandler('esx_ambulancejob:onPlayerDistress', function()
	local source = source
	if deadPlayers[source] then
		deadPlayers[source] = 'distress'
		local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")

		for _, xPlayer in pairs(Ambulance) do
			TriggerClientEvent('esx_ambulancejob:PlayerDistressed', xPlayer.source, source)
		end
	end
end)

RegisterNetEvent('esx:onPlayerSpawn')
AddEventHandler('esx:onPlayerSpawn', function()
	local source = source
	if deadPlayers[source] then
		deadPlayers[source] = nil
		local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")

		for _, xPlayer in pairs(Ambulance) do
				xPlayer.triggerEvent('esx_ambulancejob:PlayerNotDead', source)
		end
	end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	if deadPlayers[playerId] then
		deadPlayers[playerId] = nil
		local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")

		for _, xPlayer in pairs(Ambulance) do
			if xPlayer.job.name == 'ambulance' then
				xPlayer.triggerEvent('esx_ambulancejob:PlayerNotDead', playerId)
			end
		end
	end
end)

RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(target, type)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'ambulance' then
		TriggerClientEvent('esx_ambulancejob:heal', target, type)
	end
end)

ESX.RegisterServerCallback('esx_ambulancejob:removeItemsAfterRPDeath', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
	local qPlayer = QS.GetPlayerFromId(source)

    if Config.RemoveCashAfterRPDeath then
        if xPlayer.getMoney() > 0 then
            xPlayer.removeMoney(xPlayer.getMoney())
        end

        if xPlayer.getAccount('black_money').money > 0 then
            xPlayer.removeAccountMoney('black_money', xPlayer.getAccount('black_money').money)
        end
    end
    
    if Config.RemoveItemsAfterRPDeath then 
        qPlayer.ClearInventoryItems()
    end

    if Config.RemoveWeaponsAfterRPDeath then 
        qPlayer.ClearInventoryWeapons()
    end

    cb()
end)

if Config.EarlyRespawnFine then
	ESX.RegisterServerCallback('esx_ambulancejob:checkBalance', function(source, cb)
		local xPlayer = ESX.GetPlayerFromId(source)
		local bankBalance = xPlayer.getAccount('bank').money

		cb(bankBalance >= Config.EarlyRespawnFineAmount)
	end)

	RegisterNetEvent('esx_ambulancejob:payFine')
	AddEventHandler('esx_ambulancejob:payFine', function()
		local xPlayer = ESX.GetPlayerFromId(source)
		local fineAmount = Config.EarlyRespawnFineAmount

		TriggerClientEvent('qs-core:Notify', xPlayer.source, "Je hebt €"..ESX.Math.GroupDigits(fineAmount).. " betaald", "success")
		xPlayer.removeAccountMoney('bank', fineAmount, "Respawn Fine")
	end)
end

ESX.RegisterServerCallback('esx_ambulancejob:getItemAmount', function(source, cb, item)
	local xPlayer = ESX.GetPlayerFromId(source)
	local quantity = xPlayer.getInventoryItem(item).count

	cb(quantity)
end)

ESX.RegisterServerCallback('esx_ambulancejob:buyJobVehicle', function(source, cb, vehicleProps, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = getPriceFromHash(vehicleProps.model, xPlayer.job.grade_name, type)

	-- vehicle model not found
	if price == 0 then
		cb(false)
	else
		if xPlayer.getMoney() >= price then
			xPlayer.removeMoney(price, "Job Vehicle Purchase")

			MySQL.insert('INSERT INTO owned_vehicles (owner, vehicle, plate, type, job, `stored`) VALUES (?, ?, ?, ?, ?, ?)', {xPlayer.identifier, json.encode(vehicleProps), vehicleProps.plate, type, xPlayer.job.name, true},
			function (rowsChanged)
				cb(true)
			end)
		else
			cb(false)
		end
	end
end)

ESX.RegisterServerCallback('esx_ambulancejob:storeNearbyVehicle', function(source, cb, plates)
	local xPlayer = ESX.GetPlayerFromId(source)

	local plate = MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE owner = ? AND plate IN (?) AND job = ?', {xPlayer.identifier, plates, xPlayer.job.name})

	if plate then
		MySQL.update('UPDATE owned_vehicles SET `stored` = true WHERE owner = ? AND plate = ? AND job = ?', {xPlayer.identifier, plate, xPlayer.job.name},
		function(rowsChanged)
			if rowsChanged == 0 then
				cb(false)
			else
				cb(plate)
			end
		end)
	else
		cb(false)
	end
end)

function getPriceFromHash(vehicleHash, jobGrade, type)
	local vehicles = Config.AuthorizedVehicles[type][jobGrade]

	for i = 1, #vehicles do
		local vehicle = vehicles[i]
		if joaat(vehicle.model) == vehicleHash then
			return vehicle.price
		end
	end

	return 0
end

RegisterNetEvent('esx_ambulancejob:removeItem')
AddEventHandler('esx_ambulancejob:removeItem', function(item)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem(item, 1)

	if item == 'bandage' then
		TriggerClientEvent('qs-core:Notify', xPlayer.source, "Je hebt verband gebruit", "success")
	elseif item == 'medikit' then
		TriggerClientEvent('qs-core:Notify', xPlayer.source, "Je hebt een EHBO-DOOS gebruit", "success")
	end
end)

RegisterNetEvent('esx_ambulancejob:giveItem')
AddEventHandler('esx_ambulancejob:giveItem', function(itemName, amount)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name ~= 'ambulance' then
		print(('[^2WARNING^7] Player ^5%s^7 Tried Giving Themselves -> ^5' .. itemName ..'^7!'):format(xPlayer.source))
		return
	elseif (itemName ~= 'medikit' and itemName ~= 'bandage') then
		print(('[^2WARNING^7] Player ^5%s^7 Tried Giving Themselves -> ^5' .. itemName ..'^7!'):format(xPlayer.source))
		return
	end

	if xPlayer.canCarryItem(itemName, amount) then
		xPlayer.addInventoryItem(itemName, amount)
	else
		xPlayer.showNotification(TranslateCap('max_item'))
	end
end)

ESX.RegisterCommand('revive', 'admin', function(xPlayer, args, showError)
	args.playerId.triggerEvent('esx_ambulancejob:revive')
	exports['JD_logsV3']:createLog({
		EmbedMessage = " **" .. GetPlayerName(xPlayer.source) .. " (" .. xPlayer.source .. ")** deed **[ /revive ]** bij **" .. GetPlayerName(args.playerId.source) .. " (" .. args.playerId.source .. ")**",
		player_id = xPlayer.source,
		player_2_id = args.playerId.source,
		channel = "admin revive",
		screenshot = false
	})
end, true, {help = TranslateCap('revive_help'), validate = true, arguments = {
	{name = 'playerId', help = 'The player id', type = 'player'}
}})

ESX.RegisterCommand('reviveall', "admin", function(xPlayer, args, showError)
	TriggerClientEvent('esx_ambulancejob:revive', -1)
	exports['JD_logsV3']:createLog({
		EmbedMessage = " **" .. GetPlayerName(xPlayer.source) .. " (" .. xPlayer.source .. ")** deed **[ /reviveall ]**",
		player_id = xPlayer.source,
		channel = "admin revive",
		screenshot = false
	})
end, false)

ESX.RegisterUsableItem('medikit', function(source)
	if not playersHealing[source] then
		local xPlayer = ESX.GetPlayerFromId(source)
		xPlayer.removeInventoryItem('medikit', 1)

		playersHealing[source] = true
		TriggerClientEvent('esx_ambulancejob:useItem', source, 'medikit')

		Wait(10000)
		playersHealing[source] = nil
	end
end)

ESX.RegisterUsableItem('bandage', function(source)
	if not playersHealing[source] then
		local xPlayer = ESX.GetPlayerFromId(source)
		xPlayer.removeInventoryItem('bandage', 1)

		playersHealing[source] = true
		TriggerClientEvent('esx_ambulancejob:useItem', source, 'bandage')

		Wait(10000)
		playersHealing[source] = nil
	end
end)

ESX.RegisterServerCallback('esx_ambulancejob:getDeadPlayers', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == "ambulance" then 
		cb(deadPlayers)
	end
end)

ESX.RegisterServerCallback('esx_ambulancejob:getDeathStatus', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.scalar('SELECT is_dead FROM users WHERE identifier = ?', {xPlayer.identifier}, function(isDead)
		cb(isDead)
	end)
end)

RegisterNetEvent('esx_ambulancejob:setDeathStatus')
AddEventHandler('esx_ambulancejob:setDeathStatus', function(isDead)
	local xPlayer = ESX.GetPlayerFromId(source)

	if type(isDead) == 'boolean' and xPlayer then
		MySQL.update('UPDATE users SET is_dead = ? WHERE identifier = ?', {isDead, xPlayer.identifier})
		
		if not isDead then 
			local Ambulance = ESX.GetExtendedPlayers("job", "ambulance")
			for _, xPlayer in pairs(Ambulance) do
					xPlayer.triggerEvent('esx_ambulancejob:PlayerNotDead', source)
			end
		end
	end

end)
