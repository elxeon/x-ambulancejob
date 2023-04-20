ESX = exports["es_extended"]:getSharedObject()

local health
local multi
local pulse = 70
local area = "Unknown"
local lastHit
local blood = 100
local bleeding = 0

RegisterNetEvent("esx_ambulancejob:med:pakpols")
AddEventHandler("esx_ambulancejob:med:pakpols", function(source)

    local closestPlayer, closestPlayerDistance = ESX.Game.GetClosestPlayer()

    if closestPlayer == -1 or closestPlayerDistance > 3.0 then
        exports['qs-core']:Notify("Er is niemand dichtbij", "error")
    else
        if IsPlayerDead(closestPlayer) then
            exports['qs-core']:Notify(('[DOOD] Persoon: %s, Units: %s'):format(GetPlayerName(closestPlayer), closestPlayerDistance), "primary")

            blood = 100
            health = GetEntityHealth(closestPlayer)
            maxhealth = GetEntityMaxHealth(closestPlayer)
            local hit, bone = GetPedLastDamageBone(closestPlayer)

            if (bone == 31086) then

                multi = 0.0
                bleeding = 5
                area = "HEAD"
                exports['qs-core']:Notify("Persoon is in zijn hoofd geraakt!", "primary")

            elseif bone == 24817 or bone == 24818 or bone == 10706 or bone == 24816 or bone == 11816 then
               
                multi = 1.0
                bleeding = 2
                area = "BODY"
                exports['qs-core']:Notify("Persoon is in zijn lichaam geraakt!", "primary")

            else

                multi = 2.0
                bleeding = 1
                area = "LEGS/ARMS"
                exports['qs-core']:Notify("Persoon is in zijn armen/benen geraakt!", "primary")

            end
            
            pulse = ((health / 4 + 20) * multi) + math.random(0, 4)
            exports['qs-core']:Notify("[POLS] " .. pulse .. "bpm", "primary")

        else
            exports['qs-core']:Notify(('[LEVEND] Persoon: %s, Units: %s'):format(GetPlayerName(closestPlayer), closestPlayerDistance), "primary")
        end
    end
    
end, false)