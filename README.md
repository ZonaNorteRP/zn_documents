# 🚗 Jack Detran

Sistema completo de **Detran para FiveM**, inspirado no funcionamento real do DETRAN brasileiro.

Este recurso permite **registro e consulta de veículos**, **sistema de CNH com prova teórica**, **IPVA automático**, além de uma **interface NUI (HTML, CSS e JavaScript)** moderna e intuitiva.

---

## ✨ Funcionalidades

### 🪪 Sistema de CNH

* Prova teórica com perguntas configuráveis
* Quantidade mínima de acertos para aprovação
* Primeira validação gratuita (opcional)
* Taxa para refazer a prova
* Validação persistente via banco de dados

### 🚘 Registro de Veículos (Estilo DETRAN)

* Registro de veículos por **placa**
* Associação do veículo ao proprietário
* Limite máximo de veículos por jogador
* Atualização de dados do veículo
* Exclusão de registros
* Validação de placas (letras e números)

### 💰 Sistema de IPVA

* Cobrança automática por tempo (hora in-game)
* Acúmulo de dívida
* Limite máximo de débito
* Notificações periódicas de dívida
* Pagamento manual do IPVA

### 🔎 Consulta de Veículos

* Consulta pública por placa
* Exibição do dono do veículo (opcional)
* Status do IPVA
* Consulta gratuita ou paga (configurável)

### 🗺️ Detran no Mapa

* Blip configurável no mapa
* Marker de interação
* Distância personalizada para interação

### 🖥️ Interface NUI

* Desenvolvida em **HTML + CSS + JavaScript**
* Interface limpa e responsiva
* Comunicação segura com Lua (NUI Callbacks)

---

## 🧩 Dependências

> Ajuste conforme seu framework

* **QBCore** ou compatível
* **MySQL-Async** ou **oxmysql**
* FiveM Artifact atualizado

---

## 📦 Instalação

1. Baixe ou clone o repositório:

```bash
git clone https://github.com/seuusuario/jack detran
```

2. Coloque a pasta na pasta `resources` do seu servidor:

```bash
resources/[qb]/jack detran
```

3. Importe o arquivo SQL no seu banco de dados

4. Adicione no `server.cfg`:

```cfg
ensure jack detran
```

5. Configure o arquivo `config.lua` conforme sua cidade

---

## 🗄️ Banco de Dados (SQL)

O script utiliza banco de dados para armazenar:

* CNH dos jogadores
* Veículos registrados
* Débitos de IPVA

### Exemplo de tabelas utilizadas:

* `player_cnh`
* `detran_vehicles`

> O arquivo `.sql` acompanha o recurso e deve ser importado antes do uso.

---

## ⚙️ Configuração

Toda a personalização do script é feita pelo arquivo:

```lua
config.lua
```

### Principais opções configuráveis:

* Ativar/desativar **Debug**
* Localização do **Detran** no mapa
* Perguntas da **CNH**
* Valores de **registro, atualização e exclusão** de veículos
* Sistema de **IPVA** (valor, tempo, notificações)
* Consulta pública por placa
* Textos da interface (Lang)

O sistema é totalmente modular e fácil de adaptar.

---

## 🎮 Como Usar

1. Vá até o **Detran** no mapa
2. Pressione **E** para abrir o menu
3. Escolha entre:

   * Validar CNH
   * Registrar veículo
   * Consultar placa
   * Pagar IPVA
   * Atualizar ou deletar registros

---

## 🧪 Debug

Para ativar logs detalhados no console:

```lua
Config.Debug = true
```

Os logs aparecerão com a tag:

```
[JACK DETRAN DEBUG]
```

---

## 📸 Preview

> Adicione prints ou gifs da NUI aqui para valorizar o projeto.

---

## 📄 Licença

## 📄 Licença

© 2026 Jack Detran. Todos os direitos reservados.

Este script é de uso **exclusivo do autor**.
É **proibido** copiar, modificar, redistribuir, revender ou utilizar este código,
total ou parcialmente, sem autorização expressa do autor.


---

## 🤝 Créditos

Desenvolvido por **[Seu Nome / Sua Cidade RP]**
Baseado em sistemas reais do DETRAN brasileiro.

Contribuições e sugestões são bem-vindas 🚀
