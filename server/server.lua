-- Arquivo principal do servidor
local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print
local function Debug(msg)
    if Config.Debug then
        print("[ZN-DOCS] " .. msg)
    end
end

-- Inicialização
MySQL.ready(function()
    Debug("Sistema de Documentos Inicializado!")
    
    -- Criar colunas de Gestão DMV se não existirem
    MySQL.query([[
        ALTER TABLE detran_vehicles 
        ADD COLUMN IF NOT EXISTS image_url VARCHAR(255) DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS observations TEXT DEFAULT NULL;
    ]])
end)

-- Evento para processar a exibição para outro player
RegisterNetEvent('zn-docs:server:showToPlayer', function(targetId, type, data)
    local src = source
    local targetSrc = tonumber(targetId)
    
    if not targetSrc or not GetPlayerName(targetSrc) then
        return
    end

    Debug("Player " .. src .. " mostrando " .. type .. " para " .. targetId)
    TriggerClientEvent('zn-docs:client:viewDocument', targetSrc, type, data)
end)
