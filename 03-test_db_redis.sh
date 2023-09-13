#!/bin/bash

testar_conexao_mariadb(){
    if mysql -h "$HUMHUB_DB_HOST" -P "$HUMHUB_DB_PORT" -u "$HUMHUB_DB_USER" -p"$HUMHUB_DB_PASSWORD" -e "SELECT 'Conexão bem-sucedida';" 2>/dev/null; then
        return true
    else
        echo "Erro na conexao com o bd... Interronpendo o script"
        return false
    fi
}

verify_redis(){
    if [ -n "$HUMHUB_REDIS_PASSWORD" ]; then
        echo "Testando conexão com Redis usando senha..."
        if redis-cli -h ${HUMHUB_REDIS_HOSTNAME} -a ${HUMHUB_REDIS_PASSWORD}  --tls -c -p ${HUMHUB_REDIS_PORT} PING | grep -q "PONG"; then
            echo "Conexão com Redis bem-sucedida."
        else
            echo "Falha na conexão com Redis."
            exit 0
        fi
    else
        echo "Testando conexão com Redis sem senha..."
        if redis-cli -h ${HUMHUB_REDIS_HOSTNAME} --tls -c -p ${HUMHUB_REDIS_PORT} PING | grep -q "PONG"; then
            echo "Conexão com Redis bem-sucedida."
        else
            echo "Falha na conexão com Redis."
            exit 0
        fi
    fi
}

echo 'Testando conexão com o BD................................................5%'
testar_conexao_mariadb

echo 'Testando conexão com o REDIS.............................................7%'
verify_redis