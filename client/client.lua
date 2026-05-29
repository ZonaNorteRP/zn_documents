local QBCore = exports['qb-core']:GetCoreObject()
local isNUIOpen = false

-- Evento para visualizar um documento (abre a NUI)
RegisterNetEvent('zn_documents:client:viewDocument', function(type, data)
    if isNUIOpen then return end
    
    isNUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'viewDocument',
        type = type,
        data = data
    })
    
    DebugPrint("Visualizando documento: " .. type)
end)

-- Evento para mostrar documento para jogadores próximos
RegisterNetEvent('zn_documents:client:showDocumentToNearby', function(type, data)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local players = QBCore.Functions.GetPlayersFromCoords(playerCoords, 3.0)
    
    if #players <= 1 then
        QBCore.Functions.Notify("Não há ninguém por perto!", "error")
        return
    end
    
    -- Animação de mostrar algo
    RequestAnimDict("paper_1_rcm_alt1-9")
    while not HasAnimDictLoaded("paper_1_rcm_alt1-9") do Wait(10) end
    TaskPlayAnim(playerPed, "paper_1_rcm_alt1-9", "player_one_dual-9", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    for _, playerId in ipairs(players) do
        local serverId = GetPlayerServerId(playerId)
        if serverId ~= GetPlayerServerId(PlayerId()) then
            TriggerServerEvent('zn_documents:server:showDocument', serverId, type, data)
        end
    end
    
    -- Mostrar para si mesmo também
    TriggerEvent('zn_documents:client:viewDocument', type, data)
    
    Wait(3000)
    StopAnimTask(playerPed, "paper_1_rcm_alt1-9", "player_one_dual-9", 1.0)
end)

-- Fechar NUI
RegisterNUICallback('closeUI', function(data, cb)
    isNUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Debug Print
function DebugPrint(message)
    if Config.Debug then
        print("^3[ZN-DOCUMENTS DEBUG]^7 " .. message)
    end
end
