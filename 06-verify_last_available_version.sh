#!/bin/bash

echo 'Verificando última versão estável disponível............................10%'
get_latest_humhub_version
echo 'Verificando o diretório da aplicacao....................................11%'
sudo chown -R ubuntu:ubuntu /var/www/html

if [ -d ${HUMHUB_DIR} ] && [ "$(ls -A ${HUMHUB_DIR})" ]; then
    echo "O diretório do Humhub já existe e contém arquivos."
    get_installed_version
    echo "Versão local: ${INSTALLED_VERSION}"
else
    INSTALLED_VERSION=${latest_humhub_version}
    echo 'Fazendo Download dá última versão estável '${latest_humhub_version}'........12%'
    
    cd /tmp
    wget https://github.com/humhub/humhub/archive/v${latest_humhub_version}.tar.gz
    tar xzf v${latest_humhub_version}.tar.gz
    mv humhub-${latest_humhub_version} humhub
    rm v${latest_humhub_version}.tar.gz
    
    cd humhub
    echo 'Instalando dependências da aplicação... em 2s...........................13%'
    sleep 2
    
    composer config --no-plugins allow-plugins.yiisoft/yii2-composer true && \
    composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader && \
    chmod +x protected/yii && \
    chmod +x protected/yii.bat && \
    npm install grunt && \
    sudo npm install -g grunt-cli && \
    grunt build-assets && \
    sudo rm -rf ./node_modules
    cd /tmp
    mv humhub ${HUMHUB_DIR}
fi