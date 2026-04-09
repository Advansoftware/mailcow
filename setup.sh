#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}### Iniciando Configuração do Mailcow Automático ###${NC}"

# 1. Carregar config.env
if [ -f "config.env" ]; then
    source config.env
else
    echo "Erro: config.env não encontrado!"
    exit 1
fi

# 2. Configurar o repositório base se não existir
if [ ! -d "mailcow-dockerized" ]; then
    echo "Clonando repositório oficial do Mailcow..."
    git clone https://github.com/mailcow/mailcow-dockerized.git
fi

cd mailcow-dockerized || exit

# 3. Gerar mailcow.conf (Bypass interativo)
echo "Gerando mailcow.conf com FQDN: $MAILCOW_HOSTNAME"
# Respostas para o script: Hostname, Timezone, Branch (1=master)
# O script pede confirmação se o arquivo já existir.
export MAILCOW_HOSTNAME=$MAILCOW_HOSTNAME
export MAILCOW_TZ=$MAILCOW_TZ
ln -sf mailcow.conf .env
printf "%s\n%s\n1\n" "$MAILCOW_HOSTNAME" "$MAILCOW_TZ" | ./generate_config.sh

# 4. Iniciar Containers
echo "Iniciando Docker Compose..."
docker compose pull
docker compose up -d

# 5. Aguardar inicialização e Provisionar
echo "Aguardando serviços iniciarem (60s)..."
sleep 60

cd ../automation || exit
chmod +x *.sh

echo "Injetando Chave API..."
./inject_api.sh

echo "Provisionando domínios e contas..."
./provision.sh

echo -e "${GREEN}### Instalação e Configuração Concluídas! ###${NC}"
echo "Acesse: https://$MAILCOW_HOSTNAME"
echo "Admin Default: admin / moohoo (Mude imediatamente!)"
