#!/bin/bash

echo 'Definindo variáveis .....................................................0%'
NODE_MAJOR=18
PHP_VERSION=8.1
HUMHUB_DOMAIN=dominiodosistema
HUMHUB_DIR=asdf/asdf

#### USUÁRIO PADRÃO CASO O BANCO DE DADOS NAO ESTEJA CONFIGURADO
export HUMHUB_ADMIN_LOGIN='admin'
export HUMHUB_ADMIN_PASSWORD='test'
export HUMHUB_ADMIN_EMAIL='admin@humhub.example.com'
export HUMHUB_ANONYMOUS_REGISTRATION=1
export HUMHUB_ALLOW_GUEST_ACCESS=0
export HUMHUB_NEED_APPROVAL=1

export HUMHUB_CACHE_CLASS='yii\caching\FileCache'
export HUMHUB_CACHE_EXPIRE_TIME=3600

#### variáveis de banco de dados
export HUMHUB_DB_NAME="asdf"
export HUMHUB_DB_HOST="teste.us-east-1.rds.amazonaws.com"
export HUMHUB_DB_PORT="3306"
export HUMHUB_DB_USER='humhub_user'
export HUMHUB_DB_PASSWORD='asdfasdf'
export HUMHUB_NAME='Empresa'
export HUMHUB_EMAIL='humhub@tecnofoco.social'
export HUMHUB_LANG='en-US'
export HUMHUB_DEBUG='false'
export HUMHUB_TRUSTED_IPS='0.0.0.0/0'

#### Variáveis de e-mail (Precisa estar préconfigurado) ####
export HUMHUB_MAILER_SYSTEM_EMAIL_ADDRESS='humhub@humhub.example.com'
export HUMHUB_MAILER_SYSTEM_EMAIL_NAME='HumHub'
export HUMHUB_MAILER_TRANSPORT_TYPE='smtp'
export HUMHUB_MAILER_HOSTNAME='mail_server'
export HUMHUB_MAILER_PORT='25'
export HUMHUB_MAILER_USERNAME='email_username'
export HUMHUB_MAILER_PASSWORD='email_password'
export HUMHUB_MAILER_ENCRYPTION='TLS'
export HUMHUB_MAILER_ALLOW_SELF_SIGNED_CERTS=0

# Variáveis do REDIS (ELASTIC CACHE)
export HUMHUB_REDIS_HOSTNAME='cluster redis hostname'
export HUMHUB_REDIS_PORT='6582'
export HUMHUB_REDIS_PASSWORD='redis_password'


export HUMHUB_AWS_S3_BUCKET='seu bucket de arquivos'
export HUMHUB_AWS_KEY_ID='sua key'
export HUMHUB_AWS_ACCESS_KEY='sua secret key'
export HUMHUB_AWS_S3_UPLOAD_DIRECTORY="${HUMHUB_DIR}/uploads"

##### EXCLUSIVO PARA O S3 ########
S3_CONFIG_ENABLED=1
S3_BUCKET="seu bucket de arquivos de configurações"
S3_KEY=".version"
