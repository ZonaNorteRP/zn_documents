local QBCore = exports['qb-core']:GetCoreObject()

-- Criar tabelas no banco de dados
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS detran_cnh (
            citizenid VARCHAR(50) PRIMARY KEY,
            validated BOOLEAN DEFAULT 0,
            validated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS detran_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            plate VARCHAR(20) UNIQUE NOT NULL,
            owner_name VARCHAR(100) NOT NULL,
            color VARCHAR(50) NOT NULL,
            description TEXT NOT NULL,
            engine_serial VARCHAR(50) DEFAULT 'N/A',
            tire_type VARCHAR(50) DEFAULT 'Standard',
            gearbox_type VARCHAR(50) DEFAULT 'Manual',
            ipva_debt DECIMAL(10,2) DEFAULT 0,
            last_ipva_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_citizenid (citizenid),
            INDEX idx_plate (plate)
        )
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS detran_documents (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            type VARCHAR(20) NOT NULL,
            issue_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            metadata TEXT,
            INDEX idx_citizenid (citizenid)
        )
    ]], {})
    
    DebugPrint("Tabelas do banco de dados criadas/verificadas com sucesso!")
end)

-- Thread para acumular IPVA
if Config.IPVA.enabled then
    CreateThread(function()
        while true do
            Wait(Config.IPVA.cooldownMinutes * 60000) -- Converter minutos para ms
            
            -- Acumular IPVA em todos os veículos registrados
            MySQL.Async.execute([[
                UPDATE detran_vehicles 
                SET ipva_debt = ipva_debt + ?,
                    last_ipva_update = NOW()
            ]], {
                Config.IPVA.taxPerHour
            }, function(affectedRows)
                DebugPrint("IPVA acumulado em " .. affectedRows .. " veículos!")
            end)
        end
    end)
end

-- Thread para aplicar juros sobre dívidas
if Config.IPVA.enabled and Config.IPVA.interestEnabled then
    CreateThread(function()
        while true do
            Wait(Config.IPVA.interestCooldownMinutes * 60000) -- Converter minutos para ms
            
            -- Aplicar juros apenas em dívidas acima do threshold
            MySQL.Async.execute([[
                UPDATE detran_vehicles 
                SET ipva_debt = ipva_debt + (ipva_debt * ? / 100)
                WHERE ipva_debt >= ?
            ]], {
                Config.IPVA.interestRate,
                Config.IPVA.interestThreshold
            }, function(affectedRows)
                if affectedRows > 0 then
                    DebugPrint("Juros de " .. Config.IPVA.interestRate .. "% aplicados em " .. affectedRows .. " veículos!")
                    
                    -- Notificar players online sobre juros aplicados
                    local xPlayers = QBCore.Functions.GetQBPlayers()
                    for _, Player in pairs(xPlayers) do
                        local citizenid = Player.PlayerData.citizenid
                        MySQL.Async.fetchScalar('SELECT SUM(ipva_debt) FROM detran_vehicles WHERE citizenid = ? AND ipva_debt >= ?', 
                        {citizenid, Config.IPVA.interestThreshold}, function(totalDebt)
                            if totalDebt and totalDebt > 0 then
                                local interestAmount = math.floor(totalDebt * Config.IPVA.interestRate / 100)
                                TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 
                                    string.format(Config.Lang['interest_applied'], interestAmount), "error", 5000)
                            end
                        end)
                    end
                end
            end)
        end
    end)
end
-- Thread para apreender veículos com dívida alta
-- ... (mantenha o código de apreensão aqui)

-- Evento para mostrar documento a jogadores próximos
RegisterNetEvent('zn_documents:server:showDocument', function(targetId, type, data)
    local src = source
    if not targetId or not type or not data then return end
    
    if targetId == -1 then
        TriggerClientEvent('zn_documents:client:showDocumentToNearby', src, type, data)
    else
        TriggerClientEvent('zn_documents:client:viewDocument', targetId, type, data)
    end
end)

-- Handlers para o ox_inventory
CreateThread(function()
    exports('zn_drive', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local Player = QBCore.Functions.GetPlayer(inventory.id)
            if not Player then return end
            TriggerClientEvent('zn_documents:client:viewDocument', inventory.id, 'cnh', {
                name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                birthdate = Player.PlayerData.charinfo.birthdate,
                citizenid = Player.PlayerData.citizenid,
            })
            return false
        end
    end)

    exports('zn_id', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local Player = QBCore.Functions.GetPlayer(inventory.id)
            if not Player then return end
            TriggerClientEvent('zn_documents:client:viewDocument', inventory.id, 'rg', {
                name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                birthdate = Player.PlayerData.charinfo.birthdate,
                citizenid = Player.PlayerData.citizenid,
            })
            return false
        end
    end)

    exports('zn_passport', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local Player = QBCore.Functions.GetPlayer(inventory.id)
            if not Player then return end
            TriggerClientEvent('zn_documents:client:viewDocument', inventory.id, 'passport', {
                name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                birthdate = Player.PlayerData.charinfo.birthdate,
                citizenid = Player.PlayerData.citizenid,
            })
            return false
        end
    end)
end)

DebugPrint("Sistema de Documentos Zona Norte Pronto!")
DebugPrint("Script do servidor carregado com sucesso!")