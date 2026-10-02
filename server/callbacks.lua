local QBCore = exports['qb-core']:GetCoreObject()

local function CalculateDynamicIPVA(vehicle)
    if not vehicle then return 0 end
    
    local staticDebt = tonumber(vehicle.ipva_debt) or 0
    local lastUpdate = vehicle.last_ipva_update
    
    if not lastUpdate then return staticDebt end
    
    -- oxmysql returns timestamp as milliseconds Se for string, ignora
    local lastTimeMs = type(lastUpdate) == "number" and lastUpdate or (type(lastUpdate) == "string" and 0 or os.time() * 1000)
    if type(lastUpdate) == "string" then return staticDebt end 
    
    local minutesPassed = math.floor((os.time() - (lastTimeMs / 1000)) / 60)
    
    -- Quantos "ciclos" (ex: 60 minutos) se passaram desde o último pagamento/atualização?
    local cooldown = Config.IPVA.cooldownMinutes or 60
    local intervalsPassed = math.floor(minutesPassed / cooldown)
    
    if intervalsPassed <= 0 then return staticDebt end
    
    -- Valor da taxa configurado (ex: 50 por ciclo)
    local taxRate = Config.IPVA.taxPerHour or 50
    local addedDebt = intervalsPassed * taxRate
    
    local maxDebt = Config.IPVA.seizeThreshold or 30000 -- Teto máximo
    local totalDebt = staticDebt + addedDebt
    
    if totalDebt > maxDebt then totalDebt = maxDebt end
    
    return math.floor(totalDebt)
end

-- =================================================================
-- HELPER: Busca ou cria números de documento PERSISTENTES no banco
-- Garante que RG e Passaporte sejam sempre os mesmos para o cidadão
-- =================================================================
local function GetOrCreateCitizenData(citizenid)
    local existing = MySQL.query.await('SELECT rg_number, passport_num FROM detran_citizen_data WHERE citizenid = ?', {citizenid})
    if existing and existing[1] then
        return existing[1]
    end
    -- Primeira vez: gera números únicos e persiste no banco
    local rg = tostring(math.random(10000000, 99999999))
    local passport = "BR" .. tostring(math.random(100000, 999999))
    MySQL.insert.await('INSERT INTO detran_citizen_data (citizenid, rg_number, passport_num) VALUES (?, ?, ?)', {citizenid, rg, passport})
    return { rg_number = rg, passport_num = passport }
end

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
    local citizenData = GetOrCreateCitizenData(Player.PlayerData.citizenid)
    return {
        fullname = charInfo.firstname .. " " .. charInfo.lastname,
        parents = "JOAO DA SILVA E MARIA DA SILVA",
        birthplace = "LOS SANTOS - SP",
        birthdate = charInfo.birthdate,
        cpf = Player.PlayerData.citizenid,
        rg = citizenData.rg_number,  -- Número fixo e persistente no banco
        issue_date = os.date("%d/%m/%Y"),
        citizenid = Player.PlayerData.citizenid
    }
end)

-- Dados para o Passaporte
lib.callback.register('zn_documents:server:getPassportData', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local charInfo = Player.PlayerData.charinfo
    local citizenData = GetOrCreateCitizenData(Player.PlayerData.citizenid)
    return {
        firstname = charInfo.firstname,
        lastname = charInfo.lastname,
        nationality = "BRASILEIRO",
        sex = charInfo.gender == 0 and "M" or "F",
        passport_num = citizenData.passport_num,  -- Número fixo e persistente no banco
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

    local removed = false
    if Player.PlayerData.money.bank >= price then
        removed = Player.Functions.RemoveMoney('bank', price, "document-issue-" .. docType)
    else
        removed = Player.Functions.RemoveMoney('cash', price, "document-issue-" .. docType)
    end
    if not removed then
        return {success = false, message = "Erro ao processar pagamento. Tente novamente."}
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
lib.callback.register('zn_documents:server:validateCNH', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local correctAnswers = 0
    if data and data.answers then
        for _, ans in ipairs(data.answers) do
            for _, q in ipairs(Config.CNH.questions) do
                if q.question == ans.question and q.correct == ans.answer then
                    correctAnswers = correctAnswers + 1
                    break
                end
            end
        end
    end
    
    if correctAnswers < Config.CNH.correctAnswersNeeded then
        return {success = false, message = Config.Lang['cnh_failed']}
    end
    
    local price = Config.CNH.validationPrice
    if price > 0 then
        if Player.PlayerData.money.cash < price and Player.PlayerData.money.bank < price then
            return {success = false, message = Config.Lang['not_enough_money']}
        end
        local removed = false
        if Player.PlayerData.money.cash >= price then
            removed = Player.Functions.RemoveMoney('cash', price, 'cnh-validation')
        else
            removed = Player.Functions.RemoveMoney('bank', price, 'cnh-validation')
        end
        if not removed then
            return {success = false, message = "Erro ao processar pagamento da CNH. Tente novamente."}
        end
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
    
    local vehicles = MySQL.query.await('SELECT * FROM detran_vehicles WHERE citizenid = ? ORDER BY created_at DESC', {Player.PlayerData.citizenid}) or {}
    for i=1, #vehicles do
        vehicles[i].ipva_debt = CalculateDynamicIPVA(vehicles[i])
    end
    return vehicles
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
    
    local removed = false
    if Player.PlayerData.money.cash >= price then
        removed = Player.Functions.RemoveMoney('cash', price, 'vehicle-register')
    else
        removed = Player.Functions.RemoveMoney('bank', price, 'vehicle-register')
    end
    if not removed then
        return {success = false, message = "Erro ao processar pagamento do registro. Tente novamente."}
    end

    local safeOwner = data.owner_name and string.sub(tostring(data.owner_name), 1, 100) or "N/A"
    local safeColor = data.color and string.sub(tostring(data.color), 1, 50) or "N/A"
    local safeDesc = data.description and string.sub(tostring(data.description), 1, 100) or "N/A"
    local safeEngine = data.engine and string.sub(tostring(data.engine), 1, 50) or "N/A"
    local safeTires = data.tires and string.sub(tostring(data.tires), 1, 50) or "Standard"
    local safeGearbox = data.gearbox and string.sub(tostring(data.gearbox), 1, 50) or "Manual"
    
    MySQL.insert.await('INSERT INTO detran_vehicles (citizenid, plate, owner_name, color, description, engine_serial, tire_type, gearbox_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
    {Player.PlayerData.citizenid, plate, safeOwner, safeColor, safeDesc, safeEngine, safeTires, safeGearbox})
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
    
    local removed = false
    if Player.PlayerData.money.cash >= price then
        removed = Player.Functions.RemoveMoney('cash', price, 'vehicle-update')
    else
        removed = Player.Functions.RemoveMoney('bank', price, 'vehicle-update')
    end
    if not removed then
        return {success = false, message = "Erro ao processar pagamento da atualização. Tente novamente."}
    end

    local safeOwner = data.owner_name and string.sub(tostring(data.owner_name), 1, 100) or "N/A"
    local safeColor = data.color and string.sub(tostring(data.color), 1, 50) or "N/A"
    local safeDesc = data.description and string.sub(tostring(data.description), 1, 100) or "N/A"
    
    MySQL.update.await('UPDATE detran_vehicles SET owner_name = ?, color = ?, description = ? WHERE plate = ? AND citizenid = ?', 
    {safeOwner, safeColor, safeDesc, data.plate, Player.PlayerData.citizenid})
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
        local removed = false
        if Player.PlayerData.money.cash >= price then
            removed = Player.Functions.RemoveMoney('cash', price, 'vehicle-delete')
        else
            removed = Player.Functions.RemoveMoney('bank', price, 'vehicle-delete')
        end
        if not removed then
            return {success = false, message = "Erro ao processar pagamento da exclusão. Tente novamente."}
        end
    end
    
    MySQL.query.await('DELETE FROM detran_vehicles WHERE plate = ? AND citizenid = ?', {plate, Player.PlayerData.citizenid})
    return {success = true}
end)

-- Consultar veículo publicamente
lib.callback.register('zn_documents:server:consultVehicle', function(source, query)
    if not Config.Consultation.allowPublicConsultation then return {success = false, message = "Consulta desativada!"} end
    local safeQuery = string.sub(tostring(query or ""), 1, 20)
    local vehicle = MySQL.query.await('SELECT * FROM detran_vehicles WHERE plate = ? OR LOWER(owner_name) LIKE ?', {string.upper(safeQuery), '%'..string.lower(safeQuery)..'%'})
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
        ipva_debt = CalculateDynamicIPVA(v),
        owner_name = Config.Consultation.showOwnerName and v.owner_name or nil
    }
end)

-- Salvar informações de gestão do DMV (Polícia/Prefeitura/Dono)
lib.callback.register('zn_documents:server:saveVehicleManagement', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Verifica no banco de dados se o veículo pertence ao jogador
    local vehicle = MySQL.query.await('SELECT citizenid FROM detran_vehicles WHERE plate = ?', {data.plate})
    
    if not vehicle or not vehicle[1] then
        return {success = false, message = "Veículo não encontrado no banco de dados."}
    end
    
    if vehicle[1].citizenid ~= citizenid then
        return {success = false, message = "Você não tem permissão para editar informações de um veículo que não é seu!"}
    end
    
    local safeImg = data.image_url and string.sub(tostring(data.image_url), 1, 500) or ""
    local safeObs = data.observations and string.sub(tostring(data.observations), 1, 2000) or ""
    
    MySQL.update.await('UPDATE detran_vehicles SET image_url = ?, observations = ? WHERE plate = ?', 
    {safeImg, safeObs, data.plate})
    
    return {success = true}
end)

-- =================================================================
-- IPVA CALLBACKS
-- =================================================================

-- Dívidas de IPVA do player
lib.callback.register('zn_documents:server:getIPVADebts', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local vehicles = MySQL.query.await('SELECT * FROM detran_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid}) or {}
    local debts = {}
    
    for i=1, #vehicles do
        local d = CalculateDynamicIPVA(vehicles[i])
        if d > 0 then
            table.insert(debts, { plate = vehicles[i].plate, owner_name = vehicles[i].owner_name, ipva_debt = d })
        end
    end
    
    return debts
end)

-- Pagar dívida de IPVA
lib.callback.register('zn_documents:server:payIPVA', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {success = false} end
    
    local vehicle = MySQL.query.await('SELECT * FROM detran_vehicles WHERE plate = ? AND citizenid = ?', {plate, Player.PlayerData.citizenid})
    if not vehicle or not vehicle[1] then return {success = false} end
    
    local debt = CalculateDynamicIPVA(vehicle[1])
    if debt <= 0 then return {success = false, message = "Sem dívida!"} end
    
    if Player.PlayerData.money.cash < debt and Player.PlayerData.money.bank < debt then
        return {success = false, message = Config.Lang['not_enough_money']}
    end
    
    local removed = false
    if Player.PlayerData.money.bank >= debt then
        removed = Player.Functions.RemoveMoney('bank', debt, 'ipva-payment')
    else
        removed = Player.Functions.RemoveMoney('cash', debt, 'ipva-payment')
    end
    if not removed then
        return {success = false, message = "Erro ao processar pagamento do IPVA. Tente novamente."}
    end

    -- Update impostômetro
    local currentImpostometro = GetResourceKvpInt('zn_documents_impostometro') or 0
    SetResourceKvpInt('zn_documents_impostometro', currentImpostometro + debt)
    
    MySQL.update.await('UPDATE detran_vehicles SET ipva_debt = 0, last_ipva_update = CURRENT_TIMESTAMP WHERE plate = ?', {plate})
    return {success = true}
end)

-- Obter total de dívidas de IPVA do player para notificações
lib.callback.register('zn_documents:server:getTotalIPVADebt', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    local result = MySQL.query.await('SELECT * FROM detran_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local totalDebt = 0
    if result then
        for i=1, #result do
            totalDebt = totalDebt + CalculateDynamicIPVA(result[i])
        end
    end
    return totalDebt
end)

-- Obter Impostômetro
lib.callback.register('zn_documents:server:getImpostometro', function(source)
    return GetResourceKvpInt('zn_documents_impostometro') or 0
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
    local dynDebt = CalculateDynamicIPVA(v)
    return {
        registered = true,
        owner = v.owner_name,
        description = v.description,
        ipva_debt = dynDebt,
        status = dynDebt > 0 and "DÉBITO PENDENTE" or "EM DIA"
    }
end)
