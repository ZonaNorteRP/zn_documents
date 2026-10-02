# ZN Documents - Sistema de Documentos e DETRAN

Script completo de Documentos e DETRAN para FiveM, desenvolvido para o servidor Zona Norte RP.
Inspirado no funcionamento real do DETRAN brasileiro.

---

## Funcionalidades

### Emissao de Documentos

| Documento | Item | Descricao |
|---|---|---|
| Identidade (RG) | id_card | Numero fixo e persistente por personagem |
| Habilitacao (CNH) | driver_license | Emitida apos aprovacao no teste teorico |
| Passaporte | passport | Numero fixo e persistente por personagem |

Os numeros de RG e Passaporte sao gerados uma unica vez e salvos no banco de dados.

---

### Teste Teorico da CNH (100% Server-Side)

- Banco de perguntas configuravel em config.lua
- Perguntas embaralhadas aleatoriamente pelo servidor a cada prova
- Correcao inteiramente no servidor - impossivel trapacear via executor NUI
- Quantidade de questoes e minimo de acertos configuravel

---

### Registro de Veiculos (CRLV Digital)

- A placa e a chave primaria - todos os dados do veiculo sao vinculados a ela
- Campos: proprietario, cor, modelo, cambio, pneu, motor, foto URL e observacoes
- Edicao inline direto na aba Meus Veiculos sem troca de tela
- Botao para copiar a placa (compativel com CEF do FiveM)
- Sanitizacao server-side em todos os campos de texto

---

### Seguranca do Back-end

- Sem SQL Injection: 100% das queries usam prepared statements
- Autorizacao por propriedade: servidor valida citizenid antes de qualquer edicao
- RemoveMoney atomico: se o pagamento falhar, o banco nao e alterado
- Validacao da CNH no servidor: impossivel enviar pontuacao falsa pela NUI
- Inputs sanitizados com limites de caracteres aplicados no servidor

---

### Sistema de IPVA Dinamico

O IPVA e calculado em tempo real, sem loops de banco de dados rodando em segundo plano.

Como funciona:
1. Ao pagar o IPVA, last_ipva_update e gravado com a data/hora atual
2. Ao consultar, o servidor calcula quantos ciclos (cooldownMinutes) se passaram
3. Divida = ciclos_passados x taxPerHour
4. A divida nao ultrapassa o seizeThreshold configurado

Resultado: 0% de CPU quando ninguem consulta. Sem UPDATE em massa no banco a cada hora.

#### Impostometro DETRAN

Cada pagamento de IPVA acumula o valor em um Impostometro global visivel na NUI.
Persiste entre reinicializacoes do servidor via SetResourceKvpInt.

---

### Consulta Publica de Veiculos

- Consulta por placa ou nome do proprietario
- Aba estritamente somente leitura - nenhum campo editavel
- Resetada automaticamente ao sair dela
- Busca limitada a 20 caracteres no servidor

---

### Meus Veiculos

- Lista todos os veiculos do jogador registrados no DETRAN
- Botao para copiar a placa
- Edicao inline de foto e observacoes sem sair da aba
- Formulario com botoes Salvar e Cancelar

---

## Dependencias

- QBCore
- oxmysql
- ox_inventory
- qbx_idcard
- ox_lib

---

## Instalacao

1. Coloque zn_documents em resources/jackscripts/
2. As tabelas SQL sao criadas automaticamente ao iniciar o recurso
3. Adicione ao server.cfg: ensure zn_documents
4. Configure o config.lua

---

## Banco de Dados (criado automaticamente)

| Tabela | Conteudo |
|---|---|
| detran_vehicles | Veiculos registrados (chave: plate) |
| detran_documents | Historico de emissao de documentos |
| detran_cnh | Registro de validacao de CNH |
| detran_citizen_data | Numeros fixos de RG e Passaporte por personagem |

---

## Configuracao (config.lua)

IPVA:
  taxPerHour = 50        (valor por ciclo)
  cooldownMinutes = 60   (duracao do ciclo: 60=1h, 1440=1 dia, 10=testes)
  seizeThreshold = 30000 (teto maximo de divida)

Veiculos:
  registrationPrice = 500
  updatePrice = 250
  deletePrice = 100
  maxVehiclesPerPlayer = 50

CNH:
  questionsRequired = 10
  correctAnswersNeeded = 7
  validationPrice = 0 (gratuito)

Consulta:
  allowPublicConsultation = true
  showOwnerName = true
  consultationPrice = 0

---

## Integracao com MDT

Outros scripts de policia podem usar o export:
  exports[zn_documents]:consultVehicle(placa)
Retorna: registered, owner, ipva_debt (calculado dinamicamente), status

---

## Debug

Config.Debug = true  -- Ativa logs com tag [ZN-DOCUMENTS DEBUG]

---

## Licenca

(c) 2026 ZN Documents - Zona Norte RP. Todos os direitos reservados.
Proibido copiar, redistribuir ou revender sem autorizacao expressa.

---

## Creditos

Desenvolvido por JackZinho para o servidor Zona Norte RP.
Baseado no funcionamento real do DETRAN brasileiro.