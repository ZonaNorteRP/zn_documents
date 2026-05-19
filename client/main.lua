local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isNUIOpen = false
local inDetranZone = false

-- Debug Print
function DebugPrint(message)
    if Config.Debug then
        print("^3[ZN-DOCUMENTS DEBUG]^7 " .. message)
    end
end

-- Inicialização
CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Criar Blip no Mapa
    local blip = AddBlipForCoord(Config.DetranLocation.coords.x, Config.DetranLocation.coords.y, Config.DetranLocation.coords.z)
    SetBlipSprite(blip, Config.DetranLocation.blipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.DetranLocation.blipScale)
    SetBlipColour(blip, Config.DetranLocation.blipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.DetranLocation.blipName)
    EndTextCommandSetBlipName(blip)
    
    DebugPrint("Blip do Detran criado com sucesso!")
end)

-- Atualizar PlayerData quando mudar
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    DebugPrint("Player carregado: " .. PlayerData.citizenid)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    if isNUIOpen then
        CloseNUI()
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- Thread para detectar proximidade do Detran
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - Config.DetranLocation.coords)
        
        if distance < 30 then
            sleep = 0
            
            -- Desenhar marcador
            if Config.DetranLocation.drawMarker then
                DrawMarker(
                    Config.DetranLocation.markerType,
                    Config.DetranLocation.coords.x,
                    Config.DetranLocation.coords.y,
                    Config.DetranLocation.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.DetranLocation.markerSize.x,
                    Config.DetranLocation.markerSize.y,
                    Config.DetranLocation.markerSize.z,
                    Config.DetranLocation.markerColor.r,
                    Config.DetranLocation.markerColor.g,
                    Config.DetranLocation.markerColor.b,
                    Config.DetranLocation.markerColor.a,
                    false, false, 2, false, nil, nil, false
                )
            end

            if distance < Config.DetranLocation.interactionDistance then
                if not inDetranZone then
                    inDetranZone = true
                    lib.showTextUI(Config.Lang['press_e'], {
                        position = "left-center",
                        icon = 'building-columns',
                        style = {
                            borderRadius = 10,
                            backgroundColor = '#0064FF',
                            color = 'white'
                        }
                    })
                    DebugPrint("Player entrou na zona do Detran")
                end
                
                -- Verificar input E
                if IsControlJustReleased(0, 38) and not isNUIOpen then
                    OpenDetranUI()
                end
            else
                if inDetranZone then
                    inDetranZone = false
                    lib.hideTextUI()
                    DebugPrint("Player saiu da zona do Detran")
                end
            end
        else
            if inDetranZone then
                inDetranZone = false
                lib.hideTextUI()
            end
        end
        
        Wait(sleep)
    end
end)

-- Função para abrir a UI
function OpenDetranUI()
    if isNUIOpen then return end
    
    DebugPrint("Abrindo UI do Detran")
    
    lib.callback('zn_documents:server:getPlayerData', false, function(data)
        if data then
            isNUIOpen = true
            SetNuiFocus(true, true)
            
            SendNUIMessage({
                action = 'openUI',
                playerData = data
            })
            
            DebugPrint("UI aberta com sucesso!")
        else
            QBCore.Functions.Notify("Erro ao carregar dados!", "error")
        end
    end)
end

-- Função para fechar a UI
function CloseNUI()
    if not isNUIOpen then return end
    
    DebugPrint("Fechando UI do Detran")
    
    isNUIOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeUI'
    })
end

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

-- NUI Callbacks

-- Obter dados do player para atualização da UI
RegisterNUICallback('getPlayerData', function(data, cb)
    lib.callback('zn_documents:server:getPlayerData', false, function(playerData)
        cb(playerData)
    end)
end)

-- Fechar UI
RegisterNUICallback('closeUI', function(data, cb)
    CloseNUI()
    cb('ok')
end)

-- Obter perguntas da CNH
RegisterNUICallback('getCNHQuestions', function(data, cb)
    DebugPrint("Obtendo perguntas da CNH")
    
    lib.callback('zn_documents:server:getCNHQuestions', false, function(questions)
        if not questions then
            DebugPrint("ERRO: Perguntas retornaram nil!")
            cb({})
            return
        end
        
        DebugPrint("Perguntas recebidas do servidor: " .. #questions)
        cb(questions)
    end)
end)

-- Validar CNH
RegisterNUICallback('validateCNH', function(data, cb)
    DebugPrint("Validando CNH com " .. data.correctAnswers .. " respostas corretas")
    
    lib.callback('zn_documents:server:validateCNH', false, function(result)
        cb(result)
        
        if result.success then
            QBCore.Functions.Notify(Config.Lang['cnh_validated'], "success")
        else
            if result.message then
                QBCore.Functions.Notify(result.message, "error")
            else
                QBCore.Functions.Notify(Config.Lang['cnh_failed'], "error")
            end
        end
    end, data.correctAnswers)
end)

-- Emitir documento físico
RegisterNUICallback('issueDocument', function(data, cb)
    DebugPrint("Solicitando emissão de documento: " .. tostring(data.type))
    
    lib.callback('zn_documents:server:issueDocument', false, function(result)
        cb(result)
    end, data.type)
end)

-- Registrar veículo
RegisterNUICallback('registerVehicle', function(data, cb)
    DebugPrint("Registrando veículo: " .. data.plate)
    
    lib.callback('zn_documents:server:registerVehicle', false, function(result)
        cb(result)
        
        if result.success then
            QBCore.Functions.Notify(Config.Lang['vehicle_registered'], "success")
        else
            QBCore.Functions.Notify(result.message or "Erro ao registrar veículo!", "error")
        end
    end, data)
end)

-- Obter veículos não registrados
RegisterNUICallback('getUnregisteredVehicles', function(data, cb)
    DebugPrint("Obtendo veículos não registrados")
    
    lib.callback('zn_documents:server:getUnregisteredVehicles', false, function(vehicles)
        if not vehicles then
            DebugPrint("AVISO: Callback retornou nil, enviando array vazio")
            cb({})
            return
        end
        
        DebugPrint("Retornando " .. #vehicles .. " veículos não registrados para NUI")
        cb(vehicles)
    end)
end)

-- Obter veículos do player
RegisterNUICallback('getMyVehicles', function(data, cb)
    DebugPrint("Obtendo veículos do player")
    
    lib.callback('zn_documents:server:getMyVehicles', false, function(vehicles)
        cb(vehicles)
    end)
end)

-- Atualizar veículo
RegisterNUICallback('updateVehicle', function(data, cb)
    DebugPrint("Atualizando veículo: " .. data.plate)
    
    lib.callback('zn_documents:server:updateVehicle', false, function(result)
        cb(result)
        
        if result.success then
            QBCore.Functions.Notify(Config.Lang['vehicle_updated'], "success")
        else
            QBCore.Functions.Notify(result.message or "Erro ao atualizar veículo!", "error")
        end
    end, data)
end)

-- Deletar veículo
RegisterNUICallback('deleteVehicle', function(data, cb)
    DebugPrint("Deletando veículo: " .. data.plate)
    
    lib.callback('zn_documents:server:deleteVehicle', false, function(result)
        cb(result)
        
        if result.success then
            QBCore.Functions.Notify(Config.Lang['vehicle_deleted'], "success")
        else
            QBCore.Functions.Notify(result.message or "Erro ao deletar veículo!", "error")
        end
    end, data.plate)
end)

-- Consultar veículo por placa
RegisterNUICallback('consultVehicle', function(data, cb)
    DebugPrint("Consultando veículo: " .. data.plate)
    
    lib.callback('zn_documents:server:consultVehicle', false, function(result)
        cb(result)
    end, data.plate)
end)

-- Obter dívidas de IPVA
RegisterNUICallback('getIPVADebts', function(data, cb)
    DebugPrint("Obtendo dívidas de IPVA")
    
    lib.callback('zn_documents:server:getIPVADebts', false, function(debts)
        cb(debts)
    end)
end)

-- Pagar IPVA
RegisterNUICallback('payIPVA', function(data, cb)
    DebugPrint("Pagando IPVA da placa: " .. data.plate)
    
    lib.callback('zn_documents:server:payIPVA', false, function(result)
        cb(result)
        
        if result.success then
            QBCore.Functions.Notify(Config.Lang['ipva_paid'], "success")
        else
            QBCore.Functions.Notify(result.message or "Erro ao pagar IPVA!", "error")
        end
    end, data.plate)
end)

-- Notificação vinda da NUI
RegisterNUICallback('notify', function(data, cb)
    if data.message then
        QBCore.Functions.Notify(data.message, data.type or "primary")
    end
    cb('ok')
end)

-- Obter cores disponíveis
RegisterNUICallback('getAvailableColors', function(data, cb)
    cb(Config.VehicleRegistration.availableColors)
end)

-- Comando unificado para acessar o Portal de Documentos
RegisterCommand('consultardocs', function()
    OpenDetranUI()
end)

-- Notificar sobre dívidas de IPVA
if Config.IPVA.enabled and Config.IPVA.notifyDebt then
    CreateThread(function()
        while true do
            Wait(Config.IPVA.notifyInterval * 60000) -- Converter minutos para ms
            
            if PlayerData and PlayerData.citizenid then
                lib.callback('zn_documents:server:getTotalIPVADebt', false, function(totalDebt)
                    if totalDebt and totalDebt > 0 then
                        QBCore.Functions.Notify(string.format(Config.Lang['ipva_debt'], totalDebt), "error")
                    end
                end)
            end
        end
    end)
end