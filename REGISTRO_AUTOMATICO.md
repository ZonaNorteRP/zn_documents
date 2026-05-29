# Sistema de Registro Automático de Veículos

## Nova Funcionalidade Implementada ✨

O sistema agora busca automaticamente os veículos do player no banco de dados `player_vehicles` e permite registro com um clique!

## Como Funciona

### 1. Seleção Automática de Veículos

Quando o player acessa "Registrar Veículo", o sistema:

1. **Busca todos os veículos** do player em `player_vehicles`
2. **Filtra os não registrados** (compara com `detran_vehicles`)
3. **Mostra uma lista visual** com:
   - Placa do veículo
   - Modelo/Nome do veículo
   - Cor detectada automaticamente
   - Número de modificações visuais

### 2. Informações Auto-Preenchidas

Ao selecionar um veículo, o sistema preenche automaticamente:

#### ✅ Placa
- Extraída diretamente de `player_vehicles.plate`
- Campo bloqueado para edição (readonly)

#### ✅ Cor
- Detectada do campo `mods.color1`
- Converte código numérico para nome (ex: 0 = "Preto Metálico")
- Player pode adicionar mais detalhes se quiser

#### ✅ Descrição
- Nome do veículo (ex: "Truffade Adder")
- Lista de modificações visuais detectadas:
  - Spoiler
  - Para-choques (dianteiro/traseiro)
  - Saias laterais
  - Escapamento
  - Capô
  - Teto
  - Insulfilm
  - Adesivos/Livery

#### ✅ Proprietário
- Nome do player preenchido automaticamente
- Pode ser editado se necessário

## Modificações Visuais Detectadas

O sistema analisa o campo `mods` do veículo e detecta:

```lua
- modSpoilers       → Spoiler
- modFrontBumper    → Para-choque Dianteiro
- modRearBumper     → Para-choque Traseiro
- modSideSkirt      → Saias Laterais
- modExhaust        → Escapamento
- modHood           → Capô
- modRoof           → Teto
- windowTint        → Insulfilm
- modLivery         → Adesivos
```

## Cores Suportadas

O sistema reconhece **138 cores diferentes** do GTA V, incluindo:

- Todas as cores metálicas
- Cores fostas
- Cores cromadas
- Cores personalizadas

Exemplos:
- `0` = Preto Metálico
- `27` = Vermelho Metálico
- `64` = Azul Metálico
- `120` = Branco
- `111` = Roxo Metálico

## Fluxo de Uso

### Opção 1: Registro Automático (Recomendado)

```
1. Player clica em "Registrar Veículo"
2. Sistema mostra lista de veículos não registrados
3. Player clica em "Selecionar" no veículo desejado
4. Formulário é preenchido automaticamente
5. Player pode editar se quiser
6. Clica em "Registrar Veículo"
7. Pronto! ✅
```

### Opção 2: Registro Manual

```
1. Player clica em "Registrar Veículo"
2. Clica em "Registro Manual"
3. Preenche todos os campos manualmente
4. Clica em "Registrar Veículo"
5. Pronto! ✅
```

## Vantagens

✅ **Rapidez** - Registro em 2 cliques
✅ **Precisão** - Sem erros de digitação na placa
✅ **Informações completas** - Detecta modificações automaticamente
✅ **Flexibilidade** - Ainda permite registro manual
✅ **Segurança** - Só mostra veículos que o player realmente possui

## Exemplo Visual

```
┌─────────────────────────────────────────────────┐
│  Seus Veículos Não Registrados                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  🚗  ABC1234                             │  │
│  │      Truffade Adder                      │  │
│  │      🎨 Preto Metálico                   │  │
│  │      🔧 5 modificações                   │  │
│  │                      [Selecionar] ────►  │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  🚗  XYZ5678                             │  │
│  │      Pegassi Zentorno                    │  │
│  │      🎨 Vermelho Metálico                │  │
│  │      🔧 3 modificações                   │  │
│  │                      [Selecionar] ────►  │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ─────────── OU ───────────                     │
│                                                 │
│         [Registro Manual]                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Arquivos Modificados

### Server-Side (`server/main.lua`)
- ✅ Novo callback: `qb-detran:server:getUnregisteredVehicles`
- ✅ Função auxiliar: `GetColorName(colorCode)`
- ✅ Detecção de modificações visuais

### Client-Side (`html/script.js`)
- ✅ Função: `loadRegisterPage()`
- ✅ Função: `displayVehicleSelection()`
- ✅ Função: `selectVehicleForRegistration()`
- ✅ Função: `showManualForm()`
- ✅ Função: `generateDescription()`
- ✅ Função: `getVehicleName()` - Mapeia 100+ veículos

### Interface (`html/index.html`)
- ✅ Página de registro agora é dinâmica
- ✅ Formulário criado via JavaScript

### Estilos (`html/style.css`)
- ✅ Novos estilos para lista de veículos
- ✅ Cards de seleção responsivos
- ✅ Animações e hover effects

## Compatibilidade

✅ **QBCore** - Totalmente compatível
✅ **ox_inventory** - Usa para verificar CNH
✅ **oxmysql** - Queries otimizadas com Async
✅ **player_vehicles** - Tabela padrão do QBCore

## Notas Técnicas

- O sistema usa `json.decode()` para ler o campo `mods`
- Cores são mapeadas usando tabela com 138 cores do GTA V
- Veículos sem nome mapeado mostram o spawn code em maiúsculas
- Sistema é totalmente retrocompatível - registro manual continua funcionando

## Testando

1. Tenha veículos em `player_vehicles`
2. Acesse o Detran
3. Clique em "Registrar Veículo"
4. Veja a lista de veículos não registrados
5. Selecione um e veja o auto-preenchimento
6. Registre e verifique em "Meus Veículos"

## Futuras Melhorias Possíveis

- 🔮 Adicionar fotos dos veículos
- 🔮 Mostrar valor estimado do veículo
- 🔮 Filtrar por tipo (super, sports, muscle, etc)
- 🔮 Busca por placa na lista
- 🔮 Ordenação (por placa, modelo, cor)
