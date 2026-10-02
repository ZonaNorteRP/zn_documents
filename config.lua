Config = {}

-- Sistema de Debug (ative para ver logs detalhados)
Config.Debug = false

-- Localização do Blip no Mapa
Config.DetranLocation = {
    coords = vector3(240.66, -1379.33, 33.74), -- Localização padrão (pode mudar)
    blipName = "Sub-Prefeitura",
    blipSprite = 498, -- Ícone de prédio governamental/prefeitura
    blipColor = 3, -- Cor azul
    blipScale = 0.8,
    drawMarker = true,
    markerType = 27, -- Tipo do marcador
    markerSize = {x = 1.0, y = 1.0, z = 1.0},
    markerColor = {r = 0, g = 100, b = 255, a = 100},
    interactionDistance = 2.5 -- Distância para abrir o menu
}

-- Sistema de Documentos
Config.Documents = {
    ['id'] = {
        item = 'id_card',
        label = 'Identidade (RG)',
        price = 1000,
        description = 'Emissão de cédula de identidade'
    },
    ['drive'] = {
        item = 'driver_license',
        label = 'Habilitação (CNH)',
        price = 1000,
        description = 'Emissão de carteira de motorista'
    },
    ['passport'] = {
        item = 'passport',
        label = 'Passaporte',
        price = 10000,
        description = 'Emissão de passaporte internacional'
    }
}

-- Sistema de CNH
Config.CNH = {
    item = 'driver_license', -- Item da CNH
    questionsRequired = 10, -- Número de perguntas no teste
    correctAnswersNeeded = 7, -- Respostas corretas necessárias
    validationPrice = 0, -- Preço para validar CNH (0 = grátis na primeira vez)
    revalidationPrice = 500, -- Preço para refazer o teste
    
    -- Perguntas do teste de CNH (adicione quantas quiser)
    questions = {
        {
            question = "Qual a velocidade máxima permitida em vias urbanas?",
            options = {"40 km/h", "50 km/h", "60 km/h", "80 km/h"},
            correct = 3 -- Índice da resposta correta (começa em 1)
        },
        {
            question = "O que significa uma placa triangular vermelha?",
            options = {"Parada obrigatória", "Proibido estacionar", "Dê a preferência", "Velocidade máxima"},
            correct = 3
        },
        {
            question = "É permitido usar o celular ao dirigir?",
            options = {"Sim, sempre", "Não, nunca", "Apenas com fone", "Apenas em emergências"},
            correct = 2
        },
        {
            question = "Qual a distância mínima para ultrapassagem?",
            options = {"1 metro", "1.5 metros", "2 metros", "Não há distância mínima"},
            correct = 2
        },
        {
            question = "O cinto de segurança é obrigatório para:",
            options = {"Apenas o motorista", "Motorista e passageiro dianteiro", "Todos os ocupantes", "Apenas em rodovias"},
            correct = 3
        },
        {
            question = "Ao avistar um pedestre na faixa, você deve:",
            options = {"Buzinar para ele passar rápido", "Acelerar para passar antes", "Parar e dar preferência", "Desviar dele"},
            correct = 3
        },
        {
            question = "A luz amarela no semáforo significa:",
            options = {"Acelere para passar", "Atenção, prepare para parar", "Pare imediatamente", "Continue normalmente"},
            correct = 2
        },
        {
            question = "É permitido estacionar em frente a entrada de garagem?",
            options = {"Sim", "Não", "Apenas se for rápido", "Depende da garagem"},
            correct = 2
        },
        {
            question = "Quantos pontos na CNH levam à suspensão?",
            options = {"10 pontos", "20 pontos", "30 pontos", "40 pontos"},
            correct = 2
        },
        {
            question = "Dirigir alcoolizado é:",
            options = {"Permitido até certo limite", "Crime", "Apenas uma infração", "Permitido à noite"},
            correct = 2
        },
        {
            question = "A sinalização horizontal amarela indica:",
            options = {"Proibido estacionar", "Faixa de pedestres", "Separação de fluxos opostos", "Área escolar"},
            correct = 3
        },
        {
            question = "Ao sair de uma garagem, você deve:",
            options = {"Sair rapidamente", "Buzinar antes de sair", "Dar preferência aos pedestres", "Ligar o pisca-alerta"},
            correct = 3
        },
        {
            question = "A ultrapassagem pela direita é:",
            options = {"Permitida sempre", "Proibida", "Permitida em vias de mão única", "Permitida apenas em rodovias"},
            correct = 2
        },
        {
            question = "Em caso de chuva, você deve:",
            options = {"Manter a velocidade normal", "Aumentar a distância de segurança", "Ultrapassar rapidamente", "Desviar das poças"},
            correct = 2
        },
        {
            question = "A validade da CNH é de:",
            options = {"2 anos", "5 anos", "10 anos", "Indefinida"},
            correct = 3
        }
    }
}

-- Sistema de Registro de Veículos
Config.VehicleRegistration = {
    registrationPrice = 500, -- Preço para registrar um veículo
    updatePrice = 250, -- Preço para atualizar informações do veículo
    deletePrice = 100, -- Preço para deletar um registro
    maxVehiclesPerPlayer = 50, -- Máximo de veículos que um player pode registrar
}

-- Sistema de IPVA
Config.IPVA = {
    enabled = true, -- Ativar/desativar todo o sistema de IPVA

    -- =============================================================
    -- COBRANÇA FIXA POR CICLO
    -- Valor cobrado de IPVA por ciclo (independente do veículo)
    taxPerHour = 50, -- R$ cobrado a cada ciclo completo

    -- Tempo do ciclo em MINUTOS. Ex: 60 = cobra a cada 1 hora real
    -- Use 1440 para cobrar 1x por dia, 60 para 1x por hora, 10 para testes
    cooldownMinutes = 60,
    -- =============================================================

    -- Teto máximo de dívida. Quando atingir esse valor, para de crescer.
    -- Serve também como threshold de apreensão.
    seizeThreshold = 30000,

    -- Notificações de IPVA atrasado
    notifyDebt = true,       -- Notificar player quando tem dívida
    notifyInterval = 30,     -- Intervalo em minutos para re-notificar
}

-- Sistema de Consulta
Config.Consultation = {
    allowPublicConsultation = true, -- Permitir consulta pública por placa
    showOwnerName = true, -- Mostrar nome do dono na consulta
    showIPVAStatus = true, -- Mostrar status do IPVA na consulta
    consultationPrice = 0, -- Preço para fazer uma consulta (0 = grátis)
}

-- Textos da UI
Config.Lang = {
    ['detran_blip'] = 'Sub-Prefeitura',
    ['press_e'] = 'Pressione **[E]** para acessar a Sub-Prefeitura',
    ['cnh_validated'] = 'CNH validada com sucesso!',
    ['cnh_failed'] = 'Você não passou no teste. Tente novamente!',
    ['not_enough_money'] = 'Você não tem dinheiro suficiente!',
    ['vehicle_registered'] = 'Veículo registrado com sucesso!',
    ['vehicle_updated'] = 'Informações atualizadas com sucesso!',
    ['vehicle_deleted'] = 'Registro deletado com sucesso!',
    ['ipva_paid'] = 'IPVA pago com sucesso!',
    ['plate_exists'] = 'Esta placa já está registrada!',
    ['plate_not_found'] = 'Placa não encontrada!',
    ['max_vehicles'] = 'Você atingiu o limite máximo de veículos registrados!',
    ['invalid_plate'] = 'Placa inválida! Use apenas letras e números.',
    ['fill_all_fields'] = 'Preencha todos os campos!',
    ['ipva_debt'] = 'Você tem ~r~$%s~w~ de dívida de IPVA!',
    ['already_validated'] = 'Sua CNH já está validada!',
    ['interest_applied'] = 'Juros de ~r~$%s~w~ aplicados sobre suas dívidas de IPVA!',
    ['vehicle_seized'] = 'Seu veículo ~r~%s~w~ foi apreendido por dívida de IPVA de ~r~$%s~w~!',
}

-- Função para printar debug
function DebugPrint(message)
    if Config.Debug then
        print("^3[ZN-DOCUMENTS DEBUG]^7 " .. message)
    end
end