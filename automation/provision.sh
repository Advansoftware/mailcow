#!/bin/bash

# Carrega as configurações
if [ -f "../config.env" ]; then
    export $(grep -v '^#' ../config.env | xargs)
else
    echo "Erro: config.env não encontrado em ../config.env"
    exit 1
fi

API_URL="https://$MAILCOW_HOSTNAME/api/v1"
API_KEY="$INTERNAL_API_KEY"

# Função para fazer chamadas à API
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    curl -k -s -X "$method" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$API_URL/$endpoint"
}

echo "--- Iniciando Provisionamento Automático ---"

# 1. Criar Domínios
IFS=',' read -ra DOMS <<< "$COW_DOMAINS"
for domain in "${DOMS[@]}"; do
    echo "Configurando domínio: $domain"
    api_call "POST" "add/domain" "{
        \"domain\": \"$domain\",
        \"aliases\": \"100\",
        \"mailboxes\": \"100\",
        \"maxquota\": \"5120\",
        \"active\": \"1\"
    }" | jq .
done

# 2. Criar Mailboxes
IFS=',' read -ra BOXES <<< "$COW_MAILBOXES"
for box in "${BOXES[@]}"; do
    IFS=':' read -ra parts <<< "$box"
    domain=${parts[0]}
    user=${parts[1]}
    pass=${parts[2]}
    name=${parts[3]}
    
    echo "Criando conta: $user@$domain ($name)"
    api_call "POST" "add/mailbox" "{
        \"active\": \"1\",
        \"domain\": \"$domain\",
        \"local_part\": \"$user\",
        \"name\": \"$name\",
        \"password\": \"$pass\",
        \"password2\": \"$pass\",
        \"quota\": \"3072\",
        \"force_pw_update\": \"0\"
    }" | jq .
done

# 3. Criar Aliases
IFS=',' read -ra ALIASES_LIST <<< "$COW_ALIASES"
for alias_entry in "${ALIASES_LIST[@]}"; do
    IFS=':' read -ra parts <<< "$alias_entry"
    domain=${parts[0]}
    alias_name=${parts[1]}
    target=${parts[2]}
    
    echo "Criando apelido: $alias_name@$domain -> $target"
    api_call "POST" "add/alias" "{
        \"active\": \"1\",
        \"address\": \"$alias_name@$domain\",
        \"goto\": \"$target\"
    }" | jq .
done

echo "--- Provisionamento Concluído ---"
