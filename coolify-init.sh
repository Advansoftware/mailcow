#!/bin/bash

# Script de Inicialização para Coolify
# Este script prepara o ambiente do Mailcow para rodar sem intervenção interativa.

set -e

echo "### Iniciando Coolify Mailcow Setup ###"

# 1. Garantir que o diretório de dados existe
mkdir -p data/assets/ssl
mkdir -p data/conf/rspamd/override.d/

# 2. Gerar link simbólico para o .env (Coolify cria o .env, Mailcow espera mailcow.conf)
if [ ! -f mailcow.conf ]; then
    echo "Gerando mailcow.conf a partir das variáveis de ambiente..."
    
    # Valores padrão
    HOSTNAME=${MAILCOW_HOSTNAME:-mail.example.com}
    TIMEZONE=${TZ:-America/Sao_Paulo}
    
    # Gerar segredos se não existirem no ambiente
    DB_PASS=${MAILCOW_DBPASS:-$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 28)}
    DB_ROOT=${MAILCOW_DBROOT:-$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 28)}
    REDIS_PASS=${MAILCOW_REDISPASS:-$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 28)}
    SOGO_KEY=${SOGO_URL_ENCRYPTION_KEY:-$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 16)}

    cat <<EOF > mailcow.conf
# Configuração gerada automaticamente para Coolify
MAILCOW_HOSTNAME=$HOSTNAME
MAILCOW_PASS_SCHEME=BLF-CRYPT
DBNAME=mailcow
DBUSER=mailcow
DBPASS=$DB_PASS
DBROOT=$DB_ROOT
REDISPASS=$REDIS_PASS
TZ=$TIMEZONE
HTTP_PORT=${HTTP_PORT:-80}
HTTP_BIND=
HTTPS_PORT=${HTTPS_PORT:-443}
HTTPS_BIND=
HTTP_REDIRECT=y
SMTP_PORT=25
SMTPS_PORT=465
SUBMISSION_PORT=587
IMAP_PORT=143
IMAPS_PORT=993
POP_PORT=110
POPS_PORT=995
SIEVE_PORT=4190
DOVEADM_PORT=127.0.0.1:19991
SQL_PORT=127.0.0.1:13306
REDIS_PORT=127.0.0.1:7654
COMPOSE_PROJECT_NAME=mailcowdockerized
ACL_ANYONE=disallow
MAILDIR_GC_TIME=7200
ADDITIONAL_SAN=
AUTODISCOVER_SAN=y
ADDITIONAL_SERVER_NAMES=
SKIP_LETS_ENCRYPT=n
ACME_DNS_CHALLENGE=n
ACME_DNS_PROVIDER=dns_xxx
ACME_ACCOUNT_EMAIL=${ACME_ACCOUNT_EMAIL:-me@example.com}
ENABLE_SSL_SNI=n
SKIP_IP_CHECK=n
SKIP_HTTP_VERIFICATION=n
SKIP_UNBOUND_HEALTHCHECK=n
SKIP_CLAMD=${SKIP_CLAMD:-n}
SKIP_OLEFY=n
SKIP_SOGO=n
SKIP_FTS=n
FTS_HEAP=128
FTS_PROCS=1
ALLOW_ADMIN_EMAIL_LOGIN=n
USE_WATCHDOG=y
WATCHDOG_NOTIFY_BAN=n
WATCHDOG_NOTIFY_START=y
WATCHDOG_EXTERNAL_CHECKS=n
WATCHDOG_VERBOSE=n
LOG_LINES=9999
IPV4_NETWORK=172.22.1
IPV6_NETWORK=fd4d:6169:6c63:6f77::/64
MAILDIR_SUB=Maildir
SOGO_EXPIRE_SESSION=480
SOGO_URL_ENCRYPTION_KEY=$SOGO_KEY
WEBAUTHN_ONLY_TRUSTED_VENDORS=n
ENABLE_IPV6=${ENABLE_IPV6:-false}
DISABLE_NETFILTER_ISOLATION_RULE=n
EOF
    chmod 600 mailcow.conf
    echo "mailcow.conf gerado."
else
    echo "mailcow.conf já existe, pulando geração."
fi

# 3. Criar link simbólico se necessário
if [ ! -L .env ]; then
    ln -sf mailcow.conf .env
    echo "Link simbólico .env -> mailcow.conf criado."
fi

# 4. Gerar certificado "snake-oil" para o primeiro boot
if [ ! -f data/assets/ssl-example/key.pem ]; then
    mkdir -p data/assets/ssl-example
    echo "Gerando certificado provisório..."
    openssl req -x509 -newkey rsa:4096 -keyout data/assets/ssl-example/key.pem -out data/assets/ssl-example/cert.pem -days 365 -subj "/C=DE/ST=NRW/L=Willich/O=mailcow/OU=mailcow/CN=${MAILCOW_HOSTNAME:-mail.example.com}" -sha256 -nodes
    cp -n -d data/assets/ssl-example/*.pem data/assets/ssl/
fi

# 5. Criar arquivo placeholder para RSPAMD se não existir
[ ! -f ./data/conf/rspamd/override.d/worker-controller-password.inc ] && echo '# Placeholder' > ./data/conf/rspamd/override.d/worker-controller-password.inc

echo "### Setup Concluído com Sucesso! ###"
