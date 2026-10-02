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

    -- Tabela para armazenar números de documentos PERSISTENTES por cidadão
    -- Garante que o RG e Passaporte sejam sempre os mesmos (não aleatórios a cada sessão)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS detran_citizen_data (
            citizenid VARCHAR(50) PRIMARY KEY,
            rg_number VARCHAR(20) NOT NULL,
            passport_num VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})
    
    DebugPrint("Tabelas do banco de dados criadas/verificadas com sucesso!")
end)

-- As threads de IPVA em loop foram removidas.
-- O IPVA agora é calculado dinamicamente em tempo real (On-the-fly) pelo callbacks.lua,
-- usando o tempo decorrido desde o last_ipva_update, garantindo 0% de uso de CPU do servidor
-- e evitando problemas de lag ou dívidas infinitas abusivas.

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