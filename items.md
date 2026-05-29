# Itens para ox_inventory

Adicione os seguintes itens ao seu `ox_inventory/data/items.lua`:

```lua
['zn_id'] = {
    label = 'Identidade (RG)',
    weight = 10,
    stack = false,
    close = true,
    description = 'Documento de Identidade Nacional'
},

['zn_drive'] = {
    label = 'Carteira de Habilitação (CNH)',
    weight = 10,
    stack = false,
    close = true,
    description = 'Habilitação para condução de veículos'
},

['zn_passport'] = {
    label = 'Passaporte',
    weight = 20,
    stack = false,
    close = true,
    description = 'Documento de Viagem Internacional'
}
```

### Configuração no script `zn_documents`
Certifique-se de que os nomes dos itens correspondam a estes acima para que o sistema de visualização funcione corretamente.
