# Prompt para Geração de Trabalho da Faculdade (PDF)

Copie o texto abaixo e cole em uma IA (como ChatGPT, Claude ou Gemini) para gerar o conteúdo do seu trabalho de faculdade em formato acadêmico. Em seguida, você pode exportar a resposta gerada para PDF.

---

**Aja como um estudante universitário do curso de Ciência da Computação / Engenharia de Software.**

Preciso que você escreva um relatório acadêmico completo e bem estruturado para um trabalho de faculdade. O trabalho é sobre o desenvolvimento de um sistema de software distribuído, que eu criei. O sistema se chama **"ZN Documents - Sistema de Documentos e DETRAN"**, desenvolvido para a plataforma FiveM (GTA V Roleplay), utilizando a linguagem Lua (Back-end e Front-end do jogo), SQL (Banco de dados) e tecnologias Web (HTML, CSS, JavaScript) para a interface do usuário (NUI).

O relatório deve ter tom formal, acadêmico e técnico, dividido nas seguintes seções:

**1. Introdução:**
- Explique o contexto do projeto: um sistema integrado de gestão de documentos civis e controle de veículos (semelhante ao DETRAN brasileiro) para uma simulação virtual.
- Destaque o objetivo: automatizar e trazer realismo para a emissão de documentos (RG, Passaporte, CNH) e registro de veículos (CRLV), além de gerenciar impostos automáticos (IPVA).

**2. Arquitetura e Tecnologias Utilizadas:**
- **Linguagem Principal:** Lua (scripts client-side e server-side).
- **Interface Gráfica:** CEF (Chromium Embedded Framework) utilizando HTML, CSS e JavaScript (comunicação via NUI - Native UI).
- **Banco de Dados:** MySQL/MariaDB utilizando a biblioteca `oxmysql`.
- **Framework Base:** QBCore.
- **Dependências:** `ox_inventory`, `qbx_idcard` e `ox_lib`.
- **Arquitetura:** Cliente-Servidor.

**3. Funcionalidades Desenvolvidas (O que o sistema faz):**
- **Emissão de Documentos Civis:** Geração de identidades (RG) e passaportes com numeração única e persistente vinculada ao personagem no banco de dados, além da emissão de CNH (Carteira Nacional de Habilitação).
- **Sistema de Teste Teórico da CNH:** Um teste de múltipla escolha que ocorre 100% no back-end (Server-Side) para evitar trapaças (cheats). O servidor embaralha as perguntas, recebe as respostas e calcula os acertos automaticamente.
- **Registro de Veículos (CRLV Digital):** Sistema CRUD para veículos, onde a placa é a chave primária. Os dados incluem proprietário, modelo, motor, observações e até foto. Edição é feita em tempo real pela interface, com sanitização de dados no servidor.
- **Sistema de IPVA Dinâmico e Otimizado:** O cálculo de impostos atrasados (IPVA) é feito apenas no momento da consulta (lazy evaluation). O servidor calcula os ciclos de tempo que se passaram desde o último pagamento e gera a dívida automaticamente até um teto máximo. Isso economiza processamento (0% de CPU inativa) por não exigir loops rodando em segundo plano. Há também um "Impostômetro" global.
- **Consulta Pública:** Um terminal seguro, com limitação de caracteres na busca, onde os usuários podem consultar a situação de veículos pela placa ou nome do proprietário em modo "somente leitura".
- **Integração Externa:** Exportação de APIs (exports) permitindo que outros módulos (como sistemas policiais) consultem a situação dos veículos dinamicamente.

**4. Segurança e Prevenção de Falhas (Muito Importante):**
- **Prevenção contra SQL Injection:** Uso 100% de Prepared Statements nas consultas ao banco de dados.
- **Validação Server-Side:** Toda a lógica sensível (validação de CNH, pagamento de taxas, edição de veículos) ocorre no servidor. É impossível que um cliente malicioso injete dados falsos via NUI.
- **Operações Atômicas Financeiras:** Remoção de dinheiro do usuário ocorre de forma atômica; se houver falha, o banco de dados não sofre alterações indevidas.
- **Sanitização de Inputs:** Limite de caracteres e bloqueio de caracteres especiais gerenciados diretamente pelo servidor.

**5. Modelagem do Banco de Dados:**
- Descreva que o banco de dados foi modelado para criar relacionamentos sólidos. Foram criadas as tabelas:
  - `detran_vehicles`: Armazena os veículos registrados (chave primária: placa).
  - `detran_documents`: Histórico de emissões.
  - `detran_cnh`: Registro de validações do teste de motorista.
  - `detran_citizen_data`: Armazena números fixos de RG e Passaporte atrelados ao ID único do cidadão.

**6. Conclusão:**
- Faça um resumo dos resultados alcançados. Destaque como o sistema construído é robusto, otimizado para não causar gargalos de processamento no servidor (graças ao IPVA dinâmico) e totalmente seguro contra ataques de clientes maliciosos.

Por favor, escreva de forma aprofundada, com parágrafos bem desenvolvidos, pronto para eu salvar como um documento PDF e entregar para avaliação acadêmica. Use formatação em Markdown (negrito, tópicos) para facilitar a leitura.
