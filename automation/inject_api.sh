#!/bin/bash

# Carrega as configurações
if [ -f "../config.env" ]; then
    export $(grep -v '^#' ../config.env | xargs)
else
    echo "Erro: config.env não encontrado"
    exit 1
fi

echo "Aguardando banco de dados estabilizar..."
sleep 10

# Injeta a chave na tabela 'api'
# allow_from configurado para permitir a rede interna do docker e localhost
docker compose -f ../mailcow-dockerized/docker-compose.yml exec -T mysql-mailcow mysql -u${DBUSER:-mailcow} -p${DBPASS} ${DBNAME:-mailcow} <<EOF
INSERT INTO api (api_key, active, allow_from, read_only) 
VALUES ('$INTERNAL_API_KEY', 1, '172.22.1.0/24,127.0.0.1', 0)
ON DUPLICATE KEY UPDATE active=1, allow_from='172.22.1.0/24,127.0.0.1';
EOF

if [ $? -eq 0 ]; then
    echo "Chave API injetada com sucesso!"
else
    echo "Erro ao injetar chave API."
fi
