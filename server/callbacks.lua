local QBCore = exports['qb-core']:GetCoreObject()

-- =================================================================
-- PLAYER DATA CALLBACKS
-- =================================================================

-- Obter dados completos do player para a NUI
lib.callback.register('zn_documents:server:getPlayerData', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Verificar itens no inventário
    local hasLicense = (exports.ox_inventory:GetItem(source, 'driver_license', nil, true) or 0) > 0
    local hasID = (exports.ox_inventory:GetItem(source, 'id_card', nil, true) or 0) > 0
    local hasPassport = (exports.ox_inventory:GetItem(source, 'passport', nil, true) or 0) > 0
    
    -- Contagem de veículos registrados
    local vehicles = MySQL.query.await('SELECT COUNT(*) as count FROM detran_vehicles WHERE citizenid = ?', {citizenid})
    local vehicleCount = vehicles and vehicles[1] and vehicles[1].count or 0
    
    return {
        citizenid = citizenid,
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        cnhValidated = hasLicense,
        hasID = hasID,
        hasPassport = hasPassport,
        vehicleCount = vehicleCount,
        cash = Player.PlayerData.money.cash,
        bank = Player.PlayerData.money.bank
    }
end)

-- =================================================================
-- DOCUMENT DATA CALLBACKS (IDENTIDADE/PASSAPORTE/ETC)
-- =================================================================

-- Dados para o cartão de Identidade (RG)
lib.callback.register('zn_documents:server:getIdentityData', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local charInfo = Player.PlayerData.charinfo
    return {
        fullname = charInfo.firstname .. " " .. charInfo.lastname,
        parents = "JOAO DA SILVA E MARIA DA SILVA",
        birthplace = "LOS SANTOS - SP",
        birthdate = charInfo.birthdate,
        cpf = Player.PlayerData.citizenid,
        rg = math.random(10000000, 99999999),
        issue_date = os.date("%d/%m/%Y"),
        citizenid = Player.PlayerData.citizenid
    }
end)

-- Dados para o Passaporte
lib.callback.register('zn_documents:server:getPassportData', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local charInfo = Player.PlayerData.charinfo
    return {
        firstname = charInfo.firstname,
        lastname = charInfo.lastname,
        nationality = "BRASILEIRO",
        sex = charInfo.gender == 0 and "M" or "F",
        passport_num = "BR" .. math.random(100000, 999999),
        expiry = "10/10/2030",
        citizenid = Player.PlayerData.citizenid
    }
end)

-- Emitir novo documento físico (Compra)
lib.callback.register('zn_documents:server:issueDocument', function(source, docType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false, message = "Cidadão não encontrado!"} end
    
    -- Log de Rastreamento
    DebugPrint("--- NOVA SOLICITAÇÃO DE DOCUMENTO ---")
    DebugPrint("ID vindo da NUI: " .. tostring(docType))
    
    local config = Config.Documents[docType]
    if not config then 
        DebugPrint("ERRO: Configuração não encontrada para o ID: " .. tostring(docType))
        return {success = false, message = "Tipo de documento inválido!"} 
    end
    
    DebugPrint("Item configurado para este ID: " .. tostring(config.item))
    
    local price = config.price
    if Player.PlayerData.money.cash < price and Player.PlayerData.money.bank < price then
        return {success = false, message = Config.Lang['not_enough_money']}
    end
    
    if Player.PlayerData.money.bank >= price then
        Player.Functions.RemoveMoney('bank', price, "document-issue-" .. docType)
    else
        Player.Functions.RemoveMoney('cash', price, "document-issue-" .. docType)
    end
    
    -- Emitir item usando a exportação do qbx_idcard para garantir metadados corretos
    DebugPrint("Chamando qbx_idcard:CreateMetaLicense para o item: " .. tostring(config.item))
    
    local success, err = pcall(function()
        exports.qbx_idcard:CreateMetaLicense(source, config.item)
    end)

    if not success then
        print("^1[ZN-DOCUMENTS ERROR]^7 Erro ao chamar qbx_idcard: " .. tostring(err))
        return {success = false, message = "Erro interno ao emitir documento (verifique o console)."}
    end
    
    MySQL.insert.await('INSERT INTO detran_documents (citizenid, type) VALUES (?, ?)', 
    {Player.PlayerData.citizenid, docType})
    
    DebugPrint("Documento " .. tostring(config.item) .. " emitido com sucesso!")
    return {success = true}
end)

-- =================================================================
-- CNH CALLBACKS
-- =================================================================

-- Perguntas para o teste de CNH
lib.callback.register('zn_documents:server:getCNHQuestions', function(source)
    local allQuestions = Config.CNH.questions
    local count = Config.CNH.questionsRequired
    local shuffled = {}
    for i, v in ipairs(allQuestions) do shuffled[i] = v end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    local selected = {}
    for i = 1, math.min(count, #shuffled) do table.insert(selected, shuffled[i]) end
    return selected
end)

-- Validar resultado do teste de CNH
lib.callback.register('zn_documents:server:validateCNH', function(source, correctAnswers)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    if correctAnswers < Config.CNH.correctAnswersNeeded then
        return {success = false, message = Config.Lang['cnh_failed']}
    end
    
    local price = Config.CNH.validationPrice
    if price > 0 then
        if Player.PlayerData.money.cash < price and Player.PlayerData.money.bank < price then
            return {success = false, message = Config.Lang['not_enough_money']}
        end
        if Player.PlayerData.money.cash >= price then Player.Functions.RemoveMoney('cash', price)
        else Player.Functions.RemoveMoney('bank', price) end
    end
    
    -- Emitir item usando a exportação do qbx_idcard
    local success, err = pcall(function()
        exports.qbx_idcard:CreateMetaLicense(source, 'driver_license')
    end)

    if not success then
        print("^1[ZN-DOCUMENTS ERROR]^7 Erro ao emitir CNH via qbx_idcard: " .. tostring(err))
        return {success = false, message = "Erro ao emitir CNH (verifique o console)."}
    end

    return {success = true}
end)

-- =================================================================
-- VEHICLE CALLBACKS
-- =================================================================

-- Veículos do player não registrados no Detran
lib.callback.register('zn_documents:server:getUnregisteredVehicles', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local playerVehs = MySQL.query.await('SELECT plate, vehicle FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local regVehs = MySQL.query.await('SELECT plate FROM detran_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local regPlates = {}
    if regVehs then for _, v in ipairs(regVehs) do regPlates[v.plate] = true end end
    
    local unregistered = {}
    if playerVehs then
        for _, v in ipairs(playerVehs) do
            if not regPlates[v.plate] then
                table.insert(unregistered, {plate = v.plate, vehicle = v.vehicle})
            end
        end
    end
    return unregistered
end)

-- Veículos registrados no Detran
lib.callback.register('zn_documents:server:getMyVehicles', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    return MySQL.query.await('SELECT * FROM detran_vehicles WHERE citizenid = ? ORDER BY created_at DESC', {Player.PlayerData.citizenid}) or {}
end)

-- Registrar novo veículo (CRLV)
lib.callback.register('zn_documents:server:registerVehicle', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local plate = string.upper(string.gsub(data.plate, "%s+", ""))
    local existing = MySQL.query.await('SELECT id FROM detran_vehicles WHERE plate = ?', {plate})
    if existing and existing[1] then return {success = false, message = Config.Lang['plate_exists']} end
    
    local price = Config.VehicleRegistration.registrationPrice
    if Player.PlayerData.money.cash < price and Player.PlayerData.money.bank < price then
        return {success = false, message = Config.Lang['not_enough_money']}
    end
    
    if Player.PlayerData.money.cash >= price then Player.Functions.RemoveMoney('cash', price)
    else Player.Functions.RemoveMoney('bank', price) end
    
    MySQL.insert.await('INSERT INTO detran_vehicles (citizenid, plate, owner_name, color, description, engine_serial, tire_type, gearbox_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
    {Player.PlayerData.citizenid, plate, data.owner_name, data.color, data.description, data.engine or "N/A", data.tires or "Standard", data.gearbox or "Manual"})
    return {success = true}
end)

-- Atualizar dados do veículo
lib.callback.register('zn_documents:server:updateVehicle', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local price = Config.VehicleRegistration.updatePrice
    if Player.PlayerData.money.cash < price and Player.PlayerData.money.bank < price then
        return {success = false, message = Config.Lang['not_enough_money']}
    end
    
    if Player.PlayerData.money.cash >= price then Player.Functions.RemoveMoney('cash', price)
    else Player.Functions.RemoveMoney('bank', price) end
    
    MySQL.update.await('UPDATE detran_vehicles SET owner_name = ?, color = ?, description = ? WHERE plate = ? AND citizenid = ?', 
    {data.owner_name, data.color, data.description, data.plate, Player.PlayerData.citizenid})
    return {success = true}
end)

-- Deletar registro de veículo
lib.callback.register('zn_documents:server:deleteVehicle', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local price = Config.VehicleRegistration.deletePrice or 0
    if price > 0 then
        if Player.PlayerData.money.cash < price and Player.PlayerData.money.bank < price then
            return {success = false, message = Config.Lang['not_enough_money']}
        end
        if Player.PlayerData.money.cash >= price then Player.Functions.RemoveMoney('cash', price)
        else Player.Functions.RemoveMoney('bank', price) end
    end
    
    MySQL.query.await('DELETE FROM detran_vehicles WHERE plate = ? AND citizenid = ?', {plate, Player.PlayerData.citizenid})
    return {success = true}
end)

-- Consultar veículo publicamente
lib.callback.register('zn_documents:server:consultVehicle', function(source, query)
    if not Config.Consultation.allowPublicConsultation then return {success = false, message = "Consulta desativada!"} end
    local vehicle = MySQL.query.await('SELECT * FROM detran_vehicles WHERE plate = ? OR LOWER(owner_name) LIKE ?', {string.upper(query), '%'..string.lower(query)..'%'})
    if not vehicle or not vehicle[1] then return {success = false, message = Config.Lang['plate_not_found']} end
    
    local v = vehicle[1]
    return {
        success = true,
        plate = v.plate,
        color = v.color,
        description = v.description,
        engine = v.engine_serial,
        tires = v.tire_type,
        gearbox = v.gearbox_type,
        image_url = v.image_url,
        observations = v.observations,
        ipva_debt = tonumber(v.ipva_debt) or 0,
        owner_name = Config.Consultation.showOwnerName and v.owner_name or nil
    }
end)

-- Salvar informações de gestão do DMV (Polícia/Prefeitura)
lib.callback.register('zn_documents:server:saveVehicleManagement', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    -- Aqui você pode adicionar verificação de job se quiser (ex: se for policia)
    
    MySQL.update.await('UPDATE detran_vehicles SET image_url = ?, observations = ? WHERE plate = ?', 
    {data.image_url, data.observations, data.plate})
    
    return {success = true}
end)

-- =================================================================
-- IPVA CALLBACKS
-- =================================================================

-- Dívidas de IPVA do player
lib.callback.register('zn_documents:server:getIPVADebts', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    return MySQL.query.await('SELECT plate, owner_name, ipva_debt FROM detran_vehicles WHERE citizenid = ? AND ipva_debt > 0', {Player.PlayerData.citizenid}) or {}
end)

-- Pagar dívida de IPVA
lib.callback.register('zn_documents:server:payIPVA', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local vehicle = MySQL.query.await('SELECT ipva_debt FROM detran_vehicles WHERE plate = ? AND citizenid = ?', {plate, Player.PlayerData.citizenid})
    if not vehicle or not vehicle[1] then return {success = false} end
    
    local debt = math.floor(tonumber(vehicle[1].ipva_debt) or 0)
    if debt <= 0 then return {success = false, message = "Sem dívida!"} end
    
    if Player.PlayerData.money.cash < debt and Player.PlayerData.money.bank < debt then
        return {success = false, message = Config.Lang['not_enough_money']}
    end
    
    if Player.PlayerData.money.bank >= debt then Player.Functions.RemoveMoney('bank', debt)
    else Player.Functions.RemoveMoney('cash', debt) end
    
    MySQL.update.await('UPDATE detran_vehicles SET ipva_debt = 0 WHERE plate = ?', {plate})
    return {success = true}
end)

-- Obter total de dívidas de IPVA do player para notificações
lib.callback.register('zn_documents:server:getTotalIPVADebt', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    local result = MySQL.query.await('SELECT SUM(ipva_debt) as total FROM detran_vehicles WHERE citizenid = ? AND ipva_debt > 0', {Player.PlayerData.citizenid})
    if result and result[1] and result[1].total then
        return tonumber(result[1].total) or 0
    end
    
    return 0
end)

-- =================================================================
-- EXPORTS FOR INTEGRATION (MDT / POLICE)
-- =================================================================

-- Exportação para o MDT consultar o veículo
exports('consultVehicle', function(plate)
    local vehicle = MySQL.query.await('SELECT * FROM detran_vehicles WHERE plate = ?', {string.upper(plate)})
    if not vehicle or not vehicle[1] then 
        return { registered = false } 
    end
    
    local v = vehicle[1]
    return {
        registered = true,
        owner = v.owner_name,
        description = v.description,
        ipva_debt = tonumber(v.ipva_debt) or 0,
        status = (tonumber(v.ipva_debt) or 0) > 0 and "DÉBITO PENDENTE" or "EM DIA"
    }
end)
