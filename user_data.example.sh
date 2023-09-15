#!/bin/bash

echo 'definindo variáveis de ambiente.........................................01%'
export HUMHUB_DOMAIN='app.tecnofoco.social'
export HUMHUB_DIR='/var/www/html/humhub'
export HUMHUB_AWS_S3_BUCKET='bucket'
export HUMHUB_AWS_KEY_ID='key_id'
export HUMHUB_AWS_ACCESS_KEY='secret'
export HUMHUB_AWS_S3_UPLOAD_DIRECTORY="${HUMHUB_DIR}/uploads"

##### BUCKET EXCLUSIVO PARA CONFIGURAÇÕES ########
export S3_CONFIG_ENABLED=1
export S3_BUCKET="humhubconfigbucket"
export S3_KEY=".version"

sudo apt update -y && sudo apt upgrade -y
INSTALLED_VERSION=
LATEST_HUMHUB_VERSION=

echo 'Definindo conjunto de funções.................................10%'
get_latest_humhub_version() {
    #echo 'Verificando a versão da aplicação.......................................12%'
    
    
    local github_api_url="https://api.github.com/repos/humhub/humhub/releases/latest"
    local latest_version
    
    latest_version=$(curl -s "$github_api_url" | jq -r '.tag_name' | sed 's/^v//')
    
    while [[ $latest_version =~ "-RC" || $latest_version =~ "-beta" ]]; do
        # If the latest version is a pre-release, get the previous release
        local prev_version_url="https://api.github.com/repos/humhub/humhub/releases"
        latest_version=$(curl -s "$prev_version_url" | jq -r '.[1].tag_name' | sed 's/^v//')
    done
    echo "$latest_version"
    
}

get_version_file(){
    if ls "${HUMHUB_DIR}/protected/config/$S3_KEY" > /dev/null 2>&1; then
        INSTALLED_VERSION=$(cat "${HUMHUB_DIR}/protected/config/$S3_KEY")
    else
        echo "Arquivo de versao local (${HUMHUB_DIR}/protected/config/$S3_KEY) não existe"
        if aws s3 ls "s3://$S3_BUCKET/$S3_KEY" >/dev/null 2>&1; then
            # O arquivo existe, vamos verificar a versão
            echo "Copiando versao do bucket"
            aws s3 cp "s3://$S3_BUCKET/$S3_KEY" ${HUMHUB_DIR}/protected/config/$S3_KEY
            get_installed_version
        else
            echo 'Arquivo não existe no bucket...'
            zerar_versao
            get_version_file
        fi
    fi
}


get_installed_version(){
    if ls "${HUMHUB_DIR}/protected/config/$S3_KEY" >/dev/null 2>&1; then
        # O arquivo existe, vamos verificar a versão
        INSTALLED_VERSION=$(cat ${HUMHUB_DIR}/protected/config/$S3_KEY)
    else
        get_version_file
    fi
}

zerar_versao(){
    # O arquivo não existe, crie-o com a versão atual
    echo 'Zerando/Criando novo arquivo e enviando para o bucket...'
    echo '' > ${HUMHUB_DIR}/protected/config/$S3_KEY
    aws s3 cp ${HUMHUB_DIR}/protected/config/$S3_KEY "s3://$S3_BUCKET/$S3_KEY"
    echo 'Arquivo com a nova versão zerada copiado para o bucket'
}

gravar_versao(){
    echo "Gravando nova versao \"${LATEST_HUMHUB_VERSION}\" no arquivo.."
    echo $LATEST_HUMHUB_VERSION > ${HUMHUB_DIR}/protected/config/$S3_KEY
    echo "Enviando para o bucket"
    aws s3 cp ${HUMHUB_DIR}/protected/config/$S3_KEY "s3://$S3_BUCKET/$S3_KEY"
    echo "Informações da versão salvas com sucesso."
}

update_version_file(){
    get_version_file
    if aws s3 ls "s3://$S3_BUCKET/$S3_KEY" >/dev/null 2>&1; then
        # O arquivo existe, vamos verificar a versão
        aws s3 cp "s3://$S3_BUCKET/$S3_KEY" ${HUMHUB_DIR}/protected/config/$S3_KEY
        INSTALLED_VERSION=$(cat ${HUMHUB_DIR}/protected/config/$S3_KEY)
        if [[ "$INSTALLED_VERSION" != "$LATEST_HUMHUB_VERSION" ]]; then
            gravar_versao
        fi
    else
        zerar_versao
        update_version_file
    fi
}

echo 'Verificando o diretório da aplicacao....................................11%'

if [ -d ${HUMHUB_DIR} ] && [ "$(ls -A ${HUMHUB_DIR})" ]; then
    echo "O diretório do Humhub já existe e contém arquivos."
    get_installed_version
    echo "Versão local: ${INSTALLED_VERSION}"
fi
sudo chown -R ubuntu:ubuntu ${HUMHUB_DIR}
if [ -f "${HUMHUB_DIR}/protected/config/dynamic.php" ]; then
    echo  "Existing installation found!"
    
    LATEST_HUMHUB_VERSION=$(get_latest_humhub_version)
    cd ${HUMHUB_DIR}/protected/ || exit 1
    if [ "$INSTALLED_VERSION" != "$LATEST_HUMHUB_VERSION" ]; then
        echo "Updating from version $INSTALLED_VERSION to $LATEST_HUMHUB_VERSION"
        php yii migrate/up --includeModuleMigrations=1 --interactive=0
        php yii search/rebuild
        update_version_file
    fi
fi
sudo chown -R www-data:www-data ${HUMHUB_DIR}

if [ ! -f '~/.passwd-s3fs' ]; then
  echo "$HUMHUB_AWS_KEY_ID:$HUMHUB_AWS_ACCESS_KEY" >~/.passwd-s3fs
  sudo chown ubuntu:ubuntu /etc/passwd-s3fs
  chmod 600 ~/.passwd-s3fs
  sudo sed -i '/^#user_allow_other/s/^#//' /etc/fuse.conf
fi

sudo s3fs "$HUMHUB_AWS_S3_BUCKET" "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp


