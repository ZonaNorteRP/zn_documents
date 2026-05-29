# Sistema de IPVA com Juros

## Como Funciona

### 1. Acumulação de IPVA
- A cada **60 minutos** (configurável), todos os veículos registrados acumulam **$50** de IPVA
- **Não há limite máximo** - a dívida pode crescer infinitamente
- O IPVA acumula independente do veículo estar em uso ou não

### 2. Sistema de Juros
- Quando a dívida atinge **$1000** ou mais, começam a ser cobrados **juros**
- Juros de **5%** sobre o valor total da dívida
- Aplicados a cada **120 minutos** (2 horas)
- Players online são notificados quando juros são aplicados

### 3. Exemplo Prático

```
Hora 0:   Dívida = $0
Hora 1:   Dívida = $50 (IPVA acumulado)
Hora 2:   Dívida = $100 (IPVA acumulado)
...
Hora 20:  Dívida = $1000 (IPVA acumulado)
Hora 22:  Dívida = $1050 (IPVA + 5% de juros sobre $1000)
Hora 23:  Dívida = $1100 (IPVA acumulado)
Hora 24:  Dívida = $1155 (IPVA + 5% de juros sobre $1100)
```

A dívida cresce exponencialmente se não for paga!

## Configurações

No arquivo `config.lua`:

```lua
Config.IPVA = {
    enabled = true, -- Ativar/desativar sistema
    taxPerHour = 50, -- Valor cobrado por hora
    cooldownMinutes = 60, -- Tempo para acumular IPVA
    
    -- Sistema de Juros
    interestEnabled = true, -- Ativar juros
    interestThreshold = 1000, -- Dívida mínima para cobrar juros
    interestRate = 5, -- Porcentagem de juros (5%)
    interestCooldownMinutes = 120, -- Tempo para aplicar juros
    
    -- Notificações
    notifyDebt = true, -- Notificar sobre dívidas
    notifyInterval = 30, -- Intervalo de notificação
}
```

## Ajustando para Seu Servidor

### Economia Leve (Casual)
```lua
taxPerHour = 25,
cooldownMinutes = 120, -- 2 horas
interestThreshold = 2000,
interestRate = 3,
interestCooldownMinutes = 240, -- 4 horas
```

### Economia Média (Balanceada)
```lua
taxPerHour = 50,
cooldownMinutes = 60, -- 1 hora
interestThreshold = 1000,
interestRate = 5,
interestCooldownMinutes = 120, -- 2 horas
```

### Economia Pesada (Hardcore)
```lua
taxPerHour = 100,
cooldownMinutes = 30, -- 30 minutos
interestThreshold = 500,
interestRate = 10,
interestCooldownMinutes = 60, -- 1 hora
```

## Comandos Admin

```
/setipva [placa] [valor] - Define dívida manualmente
/zeroipva [placa] - Zera dívida de uma placa
```

## Notificações

Players recebem notificações:
- ✅ A cada 30 minutos se tiverem dívida
- ✅ Quando juros são aplicados
- ✅ Ao pagar IPVA com sucesso

## Pagamento

Players podem pagar no Detran:
- Ver lista de todos os veículos com dívida
- Pagar veículo por veículo
- Aceita dinheiro em mãos ou banco
- Dívida é zerada imediatamente após pagamento

## Dicas

1. **Incentive pagamentos regulares** - Juros tornam dívidas antigas muito caras
2. **Ajuste os valores** conforme a economia do seu servidor
3. **Monitore dívidas altas** - Use `/setipva` para ajustar se necessário
4. **Eventos especiais** - Considere "anistia de IPVA" em datas especiais
