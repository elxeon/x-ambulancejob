local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum
local isBusy, deadPlayers, deadPlayerBlips, isOnDuty = false, {}, {}, false
isInShopMenu = false

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

Citizen.CreateThread(function()
    while true do 
        Wait(0)
        local ped = GetPlayerPed(-1)
        local coords = GetEntityCoords(ped)
		local jobin = 'ambulance'
		local jobuit = 'ambulanceuit'

        local dist = GetDistanceBetweenCoords(coords, 310.6305, -597.0956, 43.2841, true)


        if ESX.PlayerData.job and ESX.PlayerData.job.name == ''..jobin..'' or ESX.PlayerData.job and ESX.PlayerData.job.name == ''..jobuit..'' then
			
            if dist < 1 then 
				DrawScriptText(vector3(10.6305, -597.0956, 43.2841), "[~b~E~s~] Computer")

                if IsControlJustReleased(0, 38) then
					TriggerServerEvent('esx_ambulancejob:status', jobin, jobuit)
					ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
						TriggerEvent('skinchanger:loadSkin', skin)
					end)
				end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do 
        Wait(0)
        local ped = GetPlayerPed(-1)
        local coords = GetEntityCoords(ped)

        local dist = GetDistanceBetweenCoords(coords, 304.3780, -600.3921, 43.2841, true)

        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and ESX.PlayerData.job.grade_name == 'boss' then
			
            if dist < 1 then 
				DrawScriptText(vector3(304.3780, -600.3921, 43.2841), "[~b~E~s~] Baas menu")

                if IsControlJustReleased(0, 38) then
					TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data, menu)
					end)
				end
            end
        end
    end
end)

function OpenMobileAmbulanceActionsMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_ambulance_actions', {
		title    = 'Ambulance-Acties',
		align    = 'top-right',
		elements = {
			{label = 'Main-Menu', value = 'citizen_interaction'},
			{label = 'Med-Menu', value = 'med_interaction'},
			{label = 'Brancard-Menu', value = 'brancard_interaction'},
			{label = 'Object-Menu', value = 'object_interaction'},
	}}, function(data, menu)
		if data.current.value == 'citizen_interaction' then
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = 'Main-Menu',
				align    = 'top-right',
				elements = {
					{label = 'Reanimeer-Persoon', value = 'revive'},
					{label = 'Verband-Omdoen', value = 'small'},
					{label = 'Dood-Verklaren', value = 'dood'},
				}
			}, function(data2, menu2)
				if isBusy then return end

				local closestPlayer, closestPlayerDistance = ESX.Game.GetClosestPlayer()

				if closestPlayer == -1 or closestPlayerDistance > 3.0 then
					exports['qs-core']:Notify("Er is niemand dichtbij", "error")
				else
					if data2.current.value == 'revive' then
						revivePlayer(closestPlayer)
					elseif data2.current.value == 'dood' then
						local closestPlayerPed = GetPlayerPed(closestPlayer)
						local health = GetEntityHealth(closestPlayerPed)
						local playerPed = PlayerPedId()

						if health < 1 then
							exports['qs-core']:Notify("Persoon word dood verklaart", "success")
							TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
							Wait(10000)
							ClearPedTasks(playerPed)
							print(closestPlayer)
							RemoveItemsAfterRPDeath(closestPlayer)
						else
							exports['qs-core']:Notify("Persoon is niet dood", "error")
						end
					elseif data2.current.value == 'small' then
						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = PlayerPedId()

									isBusy = true
									exports['qs-core']:Notify("Actie bezig", "success")
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Wait(10000)
									ClearPedTasks(playerPed)

									TriggerServerEvent('esx_ambulancejob:removeItem', 'bandage')
									TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'small')
									ESX.ShowNotification(TranslateCap('heal_complete', GetPlayerName(closestPlayer)))
									isBusy = false
								else
									ESX.ShowNotification(TranslateCap('player_not_conscious'))
								end
							else
								exports['qs-core']:Notify("Je hebt geen verband opzak", "error")
							end
						end, 'bandage')
					end
				end
				end, function(data2, menu2)
					menu2.close()
				end)
			elseif data.current.value == 'brancard_interaction' then
					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'brancard_interaction', {
						title    = 'Brancard-Menu',
						align    = 'top-right',
						elements	= {
							{label = 'Pak-Brancard', 				value = 'spawnbrancard'},
							{label = 'Verwijder-Brancard', 			value = 'deletebrancard'},
						}
					}, function(data2, menu2)
						if data2.current.value == 'spawnbrancard' then
							TriggerEvent("esx_ambulancejob:brancard:spawnstretcher")
						elseif data2.current.value == 'deletebrancard' then
							TriggerEvent("esx_ambulancejob:brancard:deletestretcher")
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					elseif data.current.value == 'med_interaction' then
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'med_interaction', {
							title    = 'Med-Menu',
							align    = 'top-right',
							elements	= {
								{label = 'Gegevens-Ophalen', 		value = 'checkpols'},
							}
						}, function(data2, menu2)
							if data2.current.value == 'checkpols' then
								TriggerEvent("esx_ambulancejob:med:pakpols")
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					elseif data.current.value == 'object_interaction' then
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'object_interaction', {
							title    = 'Object-Menu',
							align    = 'top-right',
							elements = {
								{label = 'Kegel', model = 'prop_roadcone02a'},
								{label = 'Lijktent', model = 'oes_lijktent'}
						}}, function(data2, menu2)
							local playerPed = PlayerPedId()
							local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
							local objectCoords = (coords + forward * 1.0)
			
							ESX.Game.SpawnObject(data2.current.model, objectCoords, function(obj)
								SetEntityHeading(obj, GetEntityHeading(playerPed))
								PlaceObjectOnGroundProperly(obj)
							end)
						end, function(data2, menu2)
							menu2.close()
						end)
					end
				end, function(data, menu)
					menu.close()
				end)
			end

function revivePlayer(closestPlayer)
	isBusy = true

	ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
		if quantity > 0 then
			local closestPlayerPed = GetPlayerPed(closestPlayer)

			if IsPedDeadOrDying(closestPlayerPed, 1) then
				local playerPed = PlayerPedId()
				local lib, anim = 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest'
				exports['qs-core']:Notify("Actie bezig", "success")

				for i=1, 15 do
					Wait(900)

					ESX.Streaming.RequestAnimDict(lib, function()
						TaskPlayAnim(playerPed, lib, anim, 8.0, -8.0, -1, 0, 0.0, false, false, false)
						RemoveAnimDict(lib)
					end)
				end

				TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
				TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
			else
				ESX.ShowNotification(TranslateCap('player_not_unconscious'))
			end
		else
			exports['qs-core']:Notify("Je hebt geen EHBO-DOOS opzak", "error")
		end
		isBusy = false
	end, 'medikit')
end

RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(healType, quiet)
	local playerPed = PlayerPedId()
	local maxHealth = GetEntityMaxHealth(playerPed)

	if healType == 'small' then
		local health = GetEntityHealth(playerPed)
		local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 8))
		SetEntityHealth(playerPed, newHealth)
	end

	if Config.Debug then 
		print("[^2INFO^7] Healing Player - ^5" .. tostring(healType).. "^7")
	end
	if not quiet then
		exports['qs-core']:Notify("Je bent geholpen", "success")
	end
end)

function FastTravel(coords, heading)
	local playerPed = PlayerPedId()

	DoScreenFadeOut(800)

	while not IsScreenFadedOut() do
		Wait(500)
	end

	ESX.Game.Teleport(playerPed, coords, function()
		DoScreenFadeIn(800)

		if heading then
			SetEntityHeading(playerPed, heading)
		end
	end)
end

-- Draw markers & Marker logic
CreateThread(function()
	while true do
		local sleep = 1500

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			local playerCoords = GetEntityCoords(PlayerPedId())
			local isInMarker, hasExited = false, false
			local currentHospital, currentPart, currentPartNum

			for hospitalNum,hospital in pairs(Config.Hospitals) do
				-- Pharmacies
				for k,v in ipairs(hospital.Pharmacies) do
					local distance = #(playerCoords - v)

					if distance < Config.DrawDistance then
						sleep = 0
						DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
						

						if distance < Config.Marker.x then
							isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Pharmacy', k
						end
					end
				end

				-- Vehicle Spawners
				for k,v in ipairs(hospital.Vehicles) do
					local distance = #(playerCoords - v.Spawner)

					if distance < Config.DrawDistance then
						sleep = 0
						DrawMarker(v.Marker.type, v.Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
						

						if distance < v.Marker.x then
							isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Vehicles', k
						end
					end
				end

				-- Helicopter Spawners
				for k,v in ipairs(hospital.Helicopters) do
					local distance = #(playerCoords - v.Spawner)

					if distance < Config.DrawDistance then
						sleep = 0
						DrawMarker(v.Marker.type, v.Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
						

						if distance < v.Marker.x then
							isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Helicopters', k
						end
					end
				end

				-- Fast Travels (Prompt)
				for k,v in ipairs(hospital.FastTravelsPrompt) do
					local distance = #(playerCoords - v.From)

					if distance < Config.DrawDistance then
						sleep = 0
						DrawMarker(v.Marker.type, v.From, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
						

						if distance < v.Marker.x then
							isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'FastTravelsPrompt', k
						end
					end
				end
			end

			-- Logic for exiting & entering markers
			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastHospital ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
					(LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('esx_ambulancejob:hasExitedMarker', LastHospital, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum = true, currentHospital, currentPart, currentPartNum

				TriggerEvent('esx_ambulancejob:hasEnteredMarker', currentHospital, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_ambulancejob:hasExitedMarker', LastHospital, LastPart, LastPartNum)
			end
		end
		Wait(sleep)
	end
end)

AddEventHandler('esx_ambulancejob:hasEnteredMarker', function(hospital, part, partNum)
	if part == 'AmbulanceActions' then
		CurrentAction = part
		CurrentActionMsg = TranslateCap('actions_prompt')
		CurrentActionData = {}
	elseif part == 'Pharmacy' then
		CurrentAction = part
		CurrentActionMsg = TranslateCap('open_pharmacy')
		CurrentActionData = {}
	elseif part == 'Vehicles' then
		CurrentAction = part
		CurrentActionMsg = TranslateCap('garage_prompt')
		CurrentActionData = {hospital = hospital, partNum = partNum}
	elseif part == 'Helicopters' then
		CurrentAction = part
		CurrentActionMsg = TranslateCap('helicopter_prompt')
		CurrentActionData = {hospital = hospital, partNum = partNum}
	elseif part == 'FastTravelsPrompt' then
		local travelItem = Config.Hospitals[hospital][part][partNum]

		CurrentAction = part
		CurrentActionMsg = travelItem.Prompt
		CurrentActionData = {to = travelItem.To.coords, heading = travelItem.To.heading}
	end

	ESX.TextUI(CurrentActionMsg)
end)

AddEventHandler('esx_ambulancejob:hasExitedMarker', function(hospital, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end
	ESX.HideUI()
	CurrentAction = nil
end)

-- Key Controls
CreateThread(function()
	while true do
		local sleep = 1500

		if CurrentAction then
			sleep = 0

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'AmbulanceActions' then
					OpenAmbulanceActionsMenu()
				elseif CurrentAction == 'Pharmacy' then
					OpenPharmacyMenu()
				elseif CurrentAction == 'Vehicles' then
					OpenVehicleSpawnerMenu('car', CurrentActionData.hospital, CurrentAction, CurrentActionData.partNum)
				elseif CurrentAction == 'Helicopters' then
					OpenVehicleSpawnerMenu('helicopter', CurrentActionData.hospital, CurrentAction, CurrentActionData.partNum)
				elseif CurrentAction == 'FastTravelsPrompt' then
					FastTravel(CurrentActionData.to, CurrentActionData.heading)
				end

				CurrentAction = nil
			end
		end
		Wait(sleep)
	end
end)

RegisterCommand("ambulance", function(src)
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and not ESX.PlayerData.dead then
		OpenMobileAmbulanceActionsMenu()
	end
end)

RegisterKeyMapping("ambulance", "Ambulance f6 openen", "keyboard", "F6")

--[[function OpenCloakroomMenu()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = TranslateCap('cloakroom'),
		align    = 'top-right',
		elements = {
			{label = TranslateCap('ems_clothes_civil'), value = 'citizen_wear'},
	}}, function(data, menu)
		if data.current.value == 'citizen_wear' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				TriggerEvent('skinchanger:loadSkin', skin)
				isOnDuty = false

				for playerId,v in pairs(deadPlayerBlips) do
					RemoveBlip(v)
					deadPlayerBlips[playerId] = nil
				end
				deadPlayers = {}
				if Config.Debug then 
					print("[^2INFO^7] Off Duty")
				end
			end)
		end
		menu.close()
	end, function(data, menu)
		menu.close()
	end)
end

function OpenPharmacyMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pharmacy', {
		title    = TranslateCap('pharmacy_menu_title'),
		align    = 'top-right',
		elements = {
			{label = TranslateCap('pharmacy_take', TranslateCap('medikit')), item = 'medikit', type = 'slider', value = 1, min = 1, max = 100},
			{label = TranslateCap('pharmacy_take', TranslateCap('bandage')), item = 'bandage', type = 'slider', value = 1, min = 1, max = 100}
	}}, function(data, menu)
		if Config.Debug then 
			print("[^2INFO^7] Attempting to Give Item - ^5" .. tostring(data.current.item) .. "^7")
		end
		TriggerServerEvent('esx_ambulancejob:giveItem', data.current.item, data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end--]]

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if isOnDuty and job.name ~= 'ambulance' then
		for playerId,v in pairs(deadPlayerBlips) do
			if Config.Debug then 
				print("[^2INFO^7] Removing dead blip - ^5" .. tostring(playerId).. "^7")
			end
			RemoveBlip(v)
			deadPlayerBlips[playerId] = nil
		end

		isOnDuty = false
	end
end)

RegisterNetEvent('esx_ambulancejob:PlayerDead')
AddEventHandler('esx_ambulancejob:PlayerDead', function(Player)
	if Config.Debug then 
		print("[^2INFO^7] Player Dead | ^5" .. tostring(Player) .. "^7")
	end
	deadPlayers[Player] = "dead"
end)

RegisterNetEvent('esx_ambulancejob:PlayerNotDead')
AddEventHandler('esx_ambulancejob:PlayerNotDead', function(Player)
	if deadPlayerBlips[Player] then
		RemoveBlip(deadPlayerBlips[Player])
		deadPlayerBlips[Player] = nil
	end
	if Config.Debug then 
		print("[^2INFO^7] Player Alive | ^5" .. tostring(Player) .. "^7")
	end
	deadPlayers[Player] = nil
end)

RegisterNetEvent('esx_ambulancejob:setDeadPlayers')
AddEventHandler('esx_ambulancejob:setDeadPlayers', function(_deadPlayers)
	deadPlayers = _deadPlayers

	if isOnDuty then
		for playerId,v in pairs(deadPlayerBlips) do
			RemoveBlip(v)
			deadPlayerBlips[playerId] = nil
		end

		for playerId,status in pairs(deadPlayers) do
			if Config.Debug then 
				print("[^2INFO^7] Player Dead | ^5" .. tostring(playerId) .. "^7")
			end
			if status == 'distress' then
				if Config.Debug then 
					print("[^2INFO^7] Creating Distress Blip for Player - ^5" .. tostring(playerId) .. "^7")
				end
				local player = GetPlayerFromServerId(playerId)
				local playerPed = GetPlayerPed(player)
				local blip = AddBlipForEntity(playerPed)

				SetBlipSprite(blip, 303)
				SetBlipColour(blip, 1)
				SetBlipFlashes(blip, true)
				SetBlipCategory(blip, 7)

				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName(TranslateCap('blip_dead'))
				EndTextCommandSetBlipName(blip)

				deadPlayerBlips[playerId] = blip
			end
		end
	end
end)


RegisterNetEvent('esx_ambulancejob:PlayerDistressed')
AddEventHandler('esx_ambulancejob:PlayerDistressed', function(Player)
	deadPlayers[Player] = 'distress'

	if isOnDuty then
		if Config.Debug then 
			print("[^2INFO^7] Player Distress Recived - ID:^5" .. tostring(Player) .. "^7")
		end
		ESX.ShowNotification("[DISPATCH]: An Unconscious Person Has Been Reported", "error", 10000)
		deadPlayerBlips[Player] = nil
		local player = GetPlayerFromServerId(Player)
		local playerPed = GetPlayerPed(player)
		local blip = AddBlipForEntity(playerPed)

		SetBlipSprite(blip, Config.DistressBlip.Sprite)
		SetBlipColour(blip, Config.DistressBlip.Color)
		SetBlipScale(blip, Config.DistressBlip.Scale)
		SetBlipFlashes(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(TranslateCap('blip_dead'))
		EndTextCommandSetBlipName(blip)

		deadPlayerBlips[Player] = blip
	end
end)

Citizen.CreateThread(function()
	while true do
        Citizen.Wait(0)
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			if removeObject == true and not removingObject then
				ESX.ShowHelpNotification('Druk ~INPUT_CONTEXT~ om dit object te verwijderen')
				if IsControlJustReleased(0, 38) then
					removingObject = true
					DeleteEntity(objectToRemove)
					removingObject = false
				end
			end
		else
			Citizen.Wait(1000)
		end
	end
end)

trackedObjects = {
    'prop_roadcone02a',
    'oes_lijktent'
}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			removeObject = false
			if not removingObject then
                for i=1, #trackedObjects, 1 do
                    local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, GetHashKey(trackedObjects[i]), false, false, false)
					if DoesEntityExist(object) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, true) then
						objectToRemove = object
						local objCoords = GetEntityCoords(object)
						local distance  = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, objCoords.x, objCoords.y, objCoords.z, true)
						if distance < 1.5 then
							removeObject = true
						end
					end
				end
			end
		else
			Citizen.Wait(1000)
		end
	end
end)

function DrawScriptText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords["x"], coords["y"], coords["z"])

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)

    local factor = string.len(text) / 370

    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 65)
end