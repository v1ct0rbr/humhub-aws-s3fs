#!/bin/bash

INSTALLED_VERSION=
latest_humhub_version=
VERSAO_EXISTENTE=

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
    latest_humhub_version=$(echo $latest_version)
    
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
    echo "Gravando nova versao \"${latest_humhub_version}\" no arquivo.."
    echo $latest_humhub_version > ${HUMHUB_DIR}/protected/config/$S3_KEY
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
        if [[ "$INSTALLED_VERSION" != "$latest_humhub_version" ]]; then
            gravar_versao
        fi
    else
        zerar_versao
        update_version_file
    fi
}