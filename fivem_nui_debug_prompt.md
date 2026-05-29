faz# 🛠️ FiveM NUI — Prompt Completo de Debug JavaScript

> Cole este prompt no Claude junto com o seu código JavaScript para obter uma análise completa de erros, avisos e melhorias específicas para NUI do FiveM.

---

## 📋 COMO USAR

1. Copie todo este documento
2. Cole no chat do Claude
3. Em seguida, cole o seu código JavaScript/HTML da NUI
4. Aguarde a análise completa

---

## 🤖 PROMPT PRINCIPAL

```
Você é um especialista em FiveM NUI (interface HTML/CSS/JS rodando no CEF/Chromium do FiveM).
Analise o código fornecido de forma completa e detalhada, verificando TODOS os pontos listados abaixo.

Para cada problema encontrado, responda no formato:
[CRÍTICO | AVISO | INFO] — Linha X (ou "geral") — Descrição clara do problema
Código problemático (se aplicável)
Código corrigido
Explicação do motivo ser um problema no contexto FiveM NUI

---

## 1. ERROS DE SINTAXE & BÁSICOS

Verifique:
- Chaves `{}`, colchetes `[]` e parênteses `()` sem par correspondente
- Vírgulas faltando ou sobrando em objetos e arrays
- Strings sem fechamento de aspas simples ou duplas
- Template literals sem fechamento de backtick
- Uso de `=` ao invés de `==` ou `===` dentro de condições `if`
- Uso de `==` onde deveria ser `===` (comparação sem verificar tipo)
- Ponto e vírgula faltando em locais críticos
- Typos em nomes de variáveis, funções ou propriedades
- Palavras reservadas do JS usadas como nomes de variáveis
- Comentários não fechados com `*/`

---

## 2. DECLARAÇÃO E USO DE VARIÁVEIS

Verifique:
- Variáveis usadas antes de serem declaradas (especialmente `let` e `const` — sem hoisting)
- `var` dentro de blocos esperando escopo de bloco (deve usar `let`)
- `const` sendo reatribuído
- Variáveis globais sendo sobrescritas acidentalmente por funções
- Variáveis declaradas e nunca utilizadas (dead variables)
- Closures em loops capturando o valor errado (usar `let` no for ou IIFE)
- Sombra de variável (variável local com mesmo nome da externa causando confusão)
- Desestruturação com chave errada retornando `undefined` silenciosamente

---

## 3. FUNÇÕES — MAPEAMENTO COMPLETO

Para CADA função no código, informe:
- Nome | Tipo (declaração / arrow / anônima / IIFE) | É chamada? (sim/não/onde) | Retorna algo? | É assíncrona?

Depois verifique:
- Funções declaradas que nunca são chamadas (dead code)
- Funções chamadas que nunca foram declaradas
- Funções arrow com `return` implícito quebrando lógica (`() => {}` vs `() => value`)
- Parâmetros obrigatórios recebendo `undefined` na chamada
- Número de argumentos na chamada diferente da declaração
- Funções com `return` inconsistente (às vezes retorna, às vezes não)
- `return` dentro de callback achando que retorna da função pai
- Recursão sem condição de parada (loop infinito)
- Funções chamadas antes de serem definidas (arrow functions não sofrem hoisting)
- `this` perdendo contexto em callbacks — verificar se precisa de `.bind(this)` ou arrow function

---

## 4. EVENTOS NUI — COMUNICAÇÃO JS ↔ LUA

Verifique:

### Listener de mensagens (JS recebendo do Lua):
- Existe `window.addEventListener('message', function(event) {...})`?
- O listener verifica `event.data.type` ou `event.data.action` antes de usar os dados?
- Os nomes dos tipos/actions batem com o que o Lua envia via `SendNUIMessage`?
- O listener está sendo adicionado mais de uma vez? (cada abertura da NUI adiciona um novo — vazamento de listeners)
- O listener é removido quando a NUI fecha? (`removeEventListener`)

### Fetch para o Lua (JS enviando para Lua):
- A URL está no formato correto: `https://cfx-nui-NOMEDORECURSO/endpoint`?
- Está usando method `POST`?
- Tem `body: JSON.stringify({...})`?
- Tem header `'Content-Type': 'application/json'`?
- A resposta do Lua está sendo aguardada com `await` ou `.then()`?
- Existe `.catch()` ou `try/catch` para tratar erro de rede?
- O Lua está respondendo com `cb({})` ou `exports.resource:callback({})`?

### Foco da NUI (CRÍTICO — trava o jogador se errar):
- `SetNuiFocus(true, true)` é chamado ao abrir a interface?
- `SetNuiFocus(false, false)` é chamado ao fechar a interface?
- A chamada de `SetNuiFocus(false, false)` está presente em TODOS os caminhos de saída?
  - Botão de fechar / X
  - Tecla ESC
  - Clique fora do modal
  - Callback de sucesso da ação
  - Callback de erro/falha
  - Timeout (se houver)

---

## 5. DOM & ESTADOS VISUAIS

Verifique:
- `document.getElementById`, `querySelector` ou `querySelectorAll` retornando `null`?
  (elemento não existe no HTML ou script roda antes do DOM carregar)
- Manipulação de DOM acontecendo fora de `DOMContentLoaded` ou equivalente?
- IDs duplicados no HTML? (causa comportamento imprevisível no `getElementById`)
- Classe CSS referenciada no JS mas não existe no CSS?
- `classList.add`, `classList.remove`, `classList.toggle` aplicados no elemento correto?
- `innerHTML` sendo usada com dados externos (risco de injeção e crash)?
- `.value` vs `.innerText` vs `.textContent` — usando a propriedade certa para cada elemento?

### Estados visuais travados:
- Elemento com `display: none` que nunca recebe `display: block` ou `flex`
- Loader ou spinner que não desaparece após operação completar
- Botão que some e não volta (toggle inconsistente)
- Overlay ou modal bloqueando cliques sem ter botão de fechar
- `overflow: hidden` em container errado travando o scroll

---

## 6. FECHAMENTO & LIMPEZA DA UI

Verifique se ao fechar a NUI:
- `SetNuiFocus(false, false)` é chamado (obrigatório)
- Inputs são limpos (`input.value = ''`)
- Estados internos são resetados (variáveis booleanas de controle, arrays, etc.)
- `setInterval` e `setTimeout` são cancelados com `clearInterval` / `clearTimeout`
- Event listeners temporários são removidos com `removeEventListener`
- Classe CSS de "aberto" é removida do container
- Dados da sessão anterior não aparecem ao reabrir

Verifique também:
- A tecla ESC está configurada para fechar? (`keydown` com `event.key === 'Escape'`)
- O listener do ESC é removido ao fechar (não acumula a cada abertura)?

---

## 7. PROBLEMAS ASSÍNCRONOS

Verifique:
- Toda Promise tem `.catch()` ou está dentro de `try/catch`
- `async/await` sem `try/catch` — erros silenciosos
- `fetch` sem verificar `response.ok` antes de usar os dados
- Race condition: NUI sendo aberta antes da anterior fechar completamente
- `setTimeout` ou `setInterval` disparando após a NUI já ter fechado
- Dependência de ordem de execução sem garantia (ex: usar resultado antes do `await`)

---

## 8. PERFORMANCE & MEMORY LEAKS

Verifique:
- `setInterval` criado a cada abertura da NUI sem `clearInterval` ao fechar
- Event listeners adicionados dentro de funções chamadas repetidamente (acumulam)
- Referências a elementos DOM grandes guardadas globalmente sem necessidade
- Animações CSS ou JS rodando mesmo com a NUI fechada (display: none não para animações JS)
- Arrays ou objetos crescendo indefinidamente sem limpeza

---

## 9. COMPATIBILIDADE CEF (FiveM)

Verifique:
- APIs de browser modernas que podem não funcionar no CEF do FiveM (ex: algumas Web APIs experimentais)
- Fontes ou recursos externos carregados via CDN (pode falhar em servidores sem acesso à internet)
- `console.log` e `console.error` deixados — aceitável para debug, mas avisar para remover em produção
- `alert()`, `confirm()` ou `prompt()` — não funcionam em NUI CEF
- Clipboard API (`navigator.clipboard`) — pode ser bloqueada no CEF

---

## 10. CHECKLIST FINAL

Ao terminar a análise, confirme cada item:

[ ] Todas as chaves, colchetes e parênteses têm par correspondente
[ ] Nenhuma string sem fechamento
[ ] window.addEventListener('message') configurado corretamente
[ ] SetNuiFocus(false, false) chamado em TODOS os caminhos de fechamento
[ ] URL do fetch com nome do recurso correto
[ ] Toda Promise com tratamento de erro
[ ] Nenhum setInterval/setTimeout sem clear ao fechar
[ ] Event listeners não duplicam a cada abertura
[ ] Nenhum getElementById retornando null
[ ] Nenhum estado visual travado (loader, overlay, display: none permanente)
[ ] Inputs limpos ao reabrir
[ ] ESC fecha a UI e libera foco
[ ] Dados da sessão anterior não aparecem ao reabrir
[ ] Nenhum = onde deveria ser === em condições
[ ] Funções chamadas com argumentos corretos

---

## FORMATO DA RESPOSTA FINAL

Organize a resposta assim:

### RESUMO
- X erros críticos encontrados
- X avisos encontrados
- X informações/melhorias sugeridas

### PROBLEMAS ENCONTRADOS
(lista detalhada com código corrigido para cada item)

### MAPA DE FUNÇÕES
(tabela com todas as funções do código)

### CHECKLIST
(checklist preenchido com ✅ ou ❌ para cada item)
```

---

## 🚦 GUIA DE SEVERIDADES

| Severidade | Significado |
|---|---|
| 🔴 **CRÍTICO** | Trava o jogador, impede a UI de funcionar, crash ou comportamento completamente errado |
| 🟡 **AVISO** | Funciona às vezes, pode falhar em condições específicas, memory leak, erro silencioso |
| 🔵 **INFO** | Melhoria de qualidade, boas práticas, performance, legibilidade |

---

## ⚡ PROMPTS RÁPIDOS (use separadamente para análises focadas)

### Só verificar funções
```
Analise APENAS as funções deste código JavaScript de FiveM NUI.
Para cada função liste: Nome | Tipo | É chamada? | Onde é chamada | Retorna algo? | É assíncrona?
Depois aponte: funções mortas, chamadas com args errados, return inconsistente, funções faltando.
```

### Só verificar eventos NUI
```
Analise APENAS a comunicação NUI↔Lua neste código.
Verifique: addEventListener('message'), fetch com URL correta, SetNuiFocus chamado em todos os caminhos de fechar, listeners duplicados, resposta do Lua sendo aguardada.
Aponte cada problema com severidade [TRAVA JOGO | ERRO FUNCIONAL | MELHORIA].
```

### Só verificar erros bobos de JS
```
Procure APENAS erros simples de JavaScript neste código:
chaves/colchetes/parênteses sem par, strings sem fechar, = ao invés de ===,
variáveis usadas antes de declarar, typos em nomes, vírgulas faltando/sobrando,
funções chamadas antes de definir, const sendo reatribuído.
Liste linha por linha.
```

### Só verificar fechamento da UI
```
Analise APENAS o fluxo de fechamento desta NUI FiveM.
Verifique: SetNuiFocus(false,false) em todos os caminhos (botão fechar, ESC, clique fora, callbacks),
clearInterval/clearTimeout, removeEventListener, limpeza de inputs, reset de variáveis.
A UI tem vazamentos de estado ao fechar e reabrir?
```

### Só verificar DOM
```
Analise APENAS o código de manipulação de DOM desta NUI FiveM.
Verifique: getElementById/querySelector retornando null, elementos travados em display:none,
loaders que não somem, innerHTML com dados externos, .value vs .innerText,
classList sendo manipulada corretamente, elementos manipulados antes do DOMContentLoaded.
```

---

## 📝 CHECKLIST MANUAL (para revisar o código você mesmo)

Marque cada item conforme for verificando:

### Sintaxe Básica
- [ ] Todas as `{` têm `}` correspondente
- [ ] Todos os `[` têm `]` correspondente  
- [ ] Todos os `(` têm `)` correspondente
- [ ] Nenhuma string com aspas sem fechar
- [ ] Nenhum template literal com backtick sem fechar
- [ ] Nenhum `=` onde deveria ser `===` em condições
- [ ] Nenhum typo em nome de variável ou função

### Funções
- [ ] Toda função declarada é chamada em algum lugar
- [ ] Toda função chamada foi declarada
- [ ] Nenhuma função recebe `undefined` por falta de argumento
- [ ] Nenhum `return` acidental dentro de callback assíncrono
- [ ] Nenhuma recursão sem condição de parada

### Eventos NUI
- [ ] `window.addEventListener('message', ...)` existe e está correto
- [ ] `event.data.type` é verificado antes de usar os dados
- [ ] Nomes dos types batem com o `SendNUIMessage` do Lua
- [ ] Listener não é adicionado mais de uma vez
- [ ] URL do fetch: `https://cfx-nui-RECURSO/endpoint`
- [ ] Fetch usa `POST` + `JSON.stringify` + header correto

### Foco & Fechamento (CRÍTICO)
- [ ] `SetNuiFocus(true, true)` ao abrir
- [ ] `SetNuiFocus(false, false)` ao fechar pelo botão X
- [ ] `SetNuiFocus(false, false)` ao pressionar ESC
- [ ] `SetNuiFocus(false, false)` ao clicar fora (se aplicável)
- [ ] `SetNuiFocus(false, false)` em callbacks de sucesso/erro

### Limpeza ao Fechar
- [ ] Inputs resetados (`input.value = ''`)
- [ ] Variáveis de estado resetadas
- [ ] `clearInterval` / `clearTimeout` chamados
- [ ] Event listeners temporários removidos
- [ ] Classes CSS de "aberto" removidas

### DOM & Visual
- [ ] Nenhum `getElementById` retornando `null`
- [ ] Nenhum loader/spinner travado
- [ ] Nenhum `display: none` permanente acidental
- [ ] `classList` manipulado no elemento correto
- [ ] `innerHTML` não recebe dados externos sem sanitização

### Assíncrono
- [ ] Toda Promise tem `.catch()` ou `try/catch`
- [ ] `fetch` verifica `response.ok`
- [ ] Nenhum `await` faltando antes de operação assíncrona

---

*Prompt criado para análise de JavaScript em FiveM NUI — compatível com Claude Sonnet*
