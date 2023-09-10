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
export HUMHUB_MAILER_SYSTEM_EMAIL_NAME='HumHub - Tecnofoco'
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


export HUMHUB_AWS_S3_BUCKET='BUCKET_UPLOAD'
export HUMHUB_AWS_KEY_ID='AWS_KEY'
export HUMHUB_AWS_ACCESS_KEY='AWS_SECRET_KEY'
export HUMHUB_AWS_S3_UPLOAD_DIRECTORY="${HUMHUB_DIR}/uploads"

##### EXCLUSIVO PARA O S3 ########
S3_CONFIG_ENABLED=1
S3_BUCKET="bucket_de_configuração"
S3_KEY=".version"


echo 'Instalando dependências..................................................1%'

sudo apt update -y && sudo apt-get install -y unattended-upgrades

sudo cp /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.backup_$(date +%s%N | cut -b1-13)

sudo sed -i '/${distro_id}:${distro_codename}-proposed/c\"${distro_id}:${distro_codename}-proposed";' "/etc/apt/apt.conf.d/50unattended-upgrades"
sudo sed -i '/${distro_id}:${distro_codename}-backports/c\"${distro_id}:${distro_codename}-backports";' "/etc/apt/apt.conf.d/50unattended-upgrades"
sudo sed -i '/${distro_id}:${distro_codename}-updates/c\"${distro_id}:${distro_codename}-updates";' "/etc/apt/apt.conf.d/50unattended-upgrades"

sudo echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";' | sudo tee "/etc/apt/apt.conf.d/10periodic" > /dev/null
sudo systemctl restart unattended-upgrades

sudo apt upgrade -y

sudo apt install -y php php-cli \
php-imagick php-curl php-bz2 php-gd php-intl php-mbstring \
php-mysql php-zip php-apcu php-xml php-ldap composer python3 jq ca-certificates s3fs fuse

sudo apt remove -y apache2

sudo apt install -y nginx \
php-fpm mariadb-client redis-tools ca-certificates curl gnupg

sudo mkdir -p /etc/apt/keyrings
if [ -f "/etc/apt/keyrings/nodesource.gpg" ]; then
    echo 'Node sourse já existe'
else
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
fi
sudo apt-get update -y
sudo apt-get install nodejs -y

sudo npm install -g npm@latest

echo 'INSTALANDO O AWS CLI....................................................10%'
sleep 2
cd ~
if [ -d "./aws/" ] && [ "$(ls -A "./aws/")" ]; then
    echo "AWS CLI já está instalado"
else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

sudo apt autoremove -y

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
# Testa a conexão com o Redis



echo 'CONFIGURANDO O PHP......................................................12%'

sudo sed -i 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i 's/post_max_size = 8M/post_max_size = 128M/g' /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /etc/php/${PHP_VERSION}/fpm/php.ini

sudo service php${PHP_VERSION}-fpm restart


echo 'Configurando o NGINX....................................................14%'

sudo bash -c 'echo "server {
    listen 80;
    listen [::]:80;

    root /var/www/html/humhub;
    server_name '${HUMHUB_DOMAIN}';

    charset utf-8;
    client_max_body_size 256M;

    location / {
        index index.php index.html;
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ ^/(protected|framework|themes/\w+/views|\.|uploads/file) {
        deny all;
    }

    location ~ ^/assets/.*\.php$ {
        deny all;
    }

    location ~ ^/(assets|static|themes|uploads) {
        expires 10d;
        add_header Cache-Control "public";
    }

    location ~ \.php {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:/var/run/php/php'$PHP_VERSION'-fpm.sock;
        try_files \$uri =404;
    }
}" > /etc/nginx/sites-available/humhub.conf'

if [ ! -e /etc/nginx/sites-enabled/humhub.conf ]; then
    sudo ln -s /etc/nginx/sites-available/humhub.conf /etc/nginx/sites-enabled/humhub.conf
else
    echo "O link simbólico já existe."
fi

sudo service nginx restart

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

# Verifique se o arquivo existe no S3
# if [[ $S3_CONFIG_ENABLED == 1 ]]; then
#     update_version_file
# fi

#sudo chown -R www-data:www-data ${HUMHUB_DIR}

BD_INSTALL_REQUIRED=false
REDIS_TESTED=false

verify_db(){
    
    local result=$(mysqlshow -h "$HUMHUB_DB_HOST" -P "$HUMHUB_DB_PORT" -u "$HUMHUB_DB_USER" -p"$HUMHUB_DB_PASSWORD" "$HUMHUB_DB_NAME" 2> /tmp/dbresults)
    
    # Verifica se o banco de dados existe e se há tabelas dentro dele
    if [[ $result == *"$HUMHUB_DB_NAME"* ]]; then
        echo "O banco de dados '$HUMHUB_DB_NAME' existe."
        
        if [[ $result == *"Tables in $HUMHUB_DB_NAME"* ]]; then
            echo "Existem tabelas no banco de dados '$HUMHUB_DB_NAME'."
        else
            echo "O banco de dados '$HUMHUB_DB_NAME' está vazio (sem tabelas internas)."
            BD_INSTALL_REQUIRED=true;
        fi
    else
        echo "O banco de dados '$HUMHUB_DB_NAME' não existe ou não é acessível em '$HUMHUB_DB_HOST'."
        BD_INSTALL_REQUIRED=true;
    fi
}

echo 'Verificando banco de dados..............................................20%'
verify_db

if [ -f "${HUMHUB_DIR}/protected/config/dynamic.php" ]; then
    echo >&3 "$0: Existing installation found!"
    
    cd ${HUMHUB_DIR}/protected/ || exit 1
    if [ "$INSTALLED_VERSION" != "$lastest_humhub_version" ]; then
        echo >&3 "$0: Updating from version $INSTALLED_VERSION to $lastest_humhub_version"
        php yii migrate/up --includeModuleMigrations=1 --interactive=0
        php yii search/rebuild
        update_version_file
    fi
else
    echo >&3 "$0: No existing installation found!"
    echo >&3 "$0: Installing source files..."
    
    update_version_file
    
    
    if [ ! -f "${HUMHUB_DIR}/protected/config/common.php" ]; then
        echo >&3 "$0: Generate config using common factory..."
        
        echo '<?php return ' \
        >${HUMHUB_DIR}/protected/config/common.php
        
        echo '<?php
                $common = [
                    "params" => [
                         "enablePjax" => false
                    ],
                    "components" => [
                        "urlManager" => [
                            "showScriptName" => false,
                            "enablePrettyUrl" => true,
                        ],
                     ]
                ];

        if (!empty(getenv("HUMHUB_REDIS_HOSTNAME"))) {
    $common["components"]["redis"] = [
        "class" => "yii\redis\Connection",
        "hostname" => getenv("HUMHUB_REDIS_HOSTNAME"),
        "port" => !empty(getenv("HUMHUB_REDIS_PORT")) ? getenv("HUMHUB_REDIS_PORT") : 6379,
        "database" => 0,
    ];
    if (!empty(getenv("HUMHUB_REDIS_PASSWORD"))) {
        $common["components"]["redis"]["password"] = getenv("HUMHUB_REDIS_PASSWORD");
    }

    if (!empty(getenv("HUMHUB_CACHE_CLASS"))) {
        $common["components"]["cache"] = [
            "class" => getenv("HUMHUB_CACHE_CLASS"),
        ];
    }

    if (!empty(getenv("HUMHUB_QUEUE_CLASS"))) {
        $common["components"]["queue"] = [
            "class" => getenv("HUMHUB_QUEUE_CLASS"),
        ];
    }

    if (!empty(getenv("HUMHUB_PUSH_URL")) && !empty(getenv("HUMHUB_PUSH_JWT_TOKEN"))) {
        $common["components"]["push"] = [
            "class" => "humhub\modules\live\driver\Push",
            "url" => getenv("HUMHUB_PUSH_URL"),
            "jwtKey" => getenv("HUMHUB_PUSH_JWT_TOKEN"),
        ];
    }
}

// Print generated common config
var_export($common);

        ' > ${HUMHUB_DIR}/protected/config/common-factory.php
        
        sh -c "php ${HUMHUB_DIR}/protected/config/common-factory.php" \
        >>${HUMHUB_DIR}/protected/config/common.php
        
        echo ';' \
        >>${HUMHUB_DIR}/protected/config/common.php
    fi
    
    if ! php -l ${HUMHUB_DIR}/protected/config/common.php; then
        echo >&3 "$0: Humhub common config is not valid! Fix errors before restarting."
        exit 1
    fi
    
    echo '<?php return
        [
            "controllerMap" => [
                "installer" => "humhub\modules\installer\commands\InstallController"
            ],
            "components" => [
                "urlManager" => [
                    "baseUrl" => "http://'${HUMHUB_DOMAIN}':80",
                    "hostInfo" => "http://'${HUMHUB_DOMAIN}':80",
                ]
            ]
    ];' > ${HUMHUB_DIR}/protected/config/console.php
    
    php ${HUMHUB_DIR}/protected/config/console.php
    
    
    
    if ! php -l ${HUMHUB_DIR}/protected/config/console.php; then
        echo >&3 "$0: Humhub console config is not valid! Fix errors before restarting."
        exit 1
    fi
    
    echo '<?php

        return [
           "components" => [
               "request" => [
                   "trustedHosts" => ["'${HUMHUB_TRUSTED_IPS}'"]
               ],
           ]
        ];
    '  > ${HUMHUB_DIR}/protected/config/web.php
    php ${HUMHUB_DIR}/protected/config/web.php
    
    if ! php -l ${HUMHUB_DIR}/protected/config/web.php; then
        echo >&3 "$0: Humhub web config is not valid! Fix errors before restarting."
        exit 1
    fi
    
    
    mkdir -p ${HUMHUB_DIR}/protected/runtime/logs/
    touch ${HUMHUB_DIR}/protected/runtime/logs/app.log
    
    
    
    echo >&3 "$0: Creating database..."
    cd ${HUMHUB_DIR}/protected/ || exit 1
    echo >&3 "$0: Installing..."
    php yii installer/write-db-config "$HUMHUB_DB_HOST" "$HUMHUB_DB_NAME" "$HUMHUB_DB_USER" "$HUMHUB_DB_PASSWORD"
    php yii installer/install-db
    php yii installer/write-site-config "$HUMHUB_NAME" "$HUMHUB_EMAIL"
    # Set baseUrl if provided
    if [ -n "$HUMHUB_PROTO" ] && [ -n "$HUMHUB_HOST" ]; then
        HUMHUB_BASE_URL="${HUMHUB_PROTO}://${HUMHUB_HOST}${HUMHUB_SUB_DIR}/"
        echo >&3 "$0: Setting base url to: $HUMHUB_BASE_URL"
        php yii installer/set-base-url "${HUMHUB_BASE_URL}"
    fi
    php yii installer/create-admin-account "${HUMHUB_ADMIN_LOGIN}" "${HUMHUB_ADMIN_EMAIL}" "${HUMHUB_ADMIN_PASSWORD}"
    
    php yii 'settings/set' 'base' 'cache.class' "${HUMHUB_CACHE_CLASS}"
    php yii 'settings/set' 'base' 'cache.expireTime' "${HUMHUB_CACHE_EXPIRE_TIME}"
    
    php yii 'settings/set' 'user' 'auth.anonymousRegistration' "${HUMHUB_ANONYMOUS_REGISTRATION}"
    php yii 'settings/set' 'user' 'auth.allowGuestAccess' "${HUMHUB_ALLOW_GUEST_ACCESS}"
    php yii 'settings/set' 'user' 'auth.needApproval' "${HUMHUB_NEED_APPROVAL}"
    
    php yii 'settings/set' 'base' 'mailer.systemEmailAddress' "${HUMHUB_MAILER_SYSTEM_EMAIL_ADDRESS}"
    php yii 'settings/set' 'base' 'mailer.systemEmailName' "${HUMHUB_MAILER_SYSTEM_EMAIL_NAME}"
    if [ "$HUMHUB_MAILER_TRANSPORT_TYPE" != "php" ]; then
        echo >&3 "$0: Setting Mailer configuration..."
        php yii 'settings/set' 'base' 'mailer.transportType' "${HUMHUB_MAILER_TRANSPORT_TYPE}"
        php yii 'settings/set' 'base' 'mailer.hostname' "${HUMHUB_MAILER_HOSTNAME}"
        php yii 'settings/set' 'base' 'mailer.port' "${HUMHUB_MAILER_PORT}"
        php yii 'settings/set' 'base' 'mailer.username' "${HUMHUB_MAILER_USERNAME}"
        php yii 'settings/set' 'base' 'mailer.password' "${HUMHUB_MAILER_PASSWORD}"
        php yii 'settings/set' 'base' 'mailer.encryption' "${HUMHUB_MAILER_ENCRYPTION}"
        php yii 'settings/set' 'base' 'mailer.allowSelfSignedCerts' "${HUMHUB_MAILER_ALLOW_SELF_SIGNED_CERTS}"
    fi
    echo "Setting permissions..."
    sudo chown -R www-data:www-data ${HUMHUB_DIR}/uploads
    sudo chown -R www-data:www-data ${HUMHUB_DIR}/protected/modules
    sudo chown -R www-data:www-data ${HUMHUB_DIR}/protected/config
    sudo chown -R www-data:www-data ${HUMHUB_DIR}/protected/runtime
    sudo chown www-data:www-data ${HUMHUB_DIR}/protected/config/dynamic.php
    
    
    # export HUMHUB_AWS_S3_BUCKET=tecnocthumhub
    # export HUMHUB_AWS_KEY_ID=AKIA2TYC7IZEDRLVWNRE
    # export HUMHUB_AWS_ACCESS_KEY='hs7mz8OEUEwIce+06purn9sQ6c3eLz0MWNAmVqVp'
    # export HUMHUB_AWS_S3_UPLOAD_DIRECTORY="${HUMHUB_DIR}/uploads"
    
    # Configurar o s3fs
    # touch ~/.passwd-s3fs
    echo "$HUMHUB_AWS_KEY_ID:$HUMHUB_AWS_ACCESS_KEY" > ~/.passwd-s3fs
    # sudo chown ubuntu:ubuntu /etc/passwd-s3fs
    chmod 600 ~/.passwd-s3fs
    sudo sed -i '/^#user_allow_other/s/^#//' /etc/fuse.conf
    aws s3 sync "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" "s3://$HUMHUB_AWS_S3_BUCKET"
    if [ -d "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" ];then
        s3fs "$HUMHUB_AWS_S3_BUCKET" "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp
       
    fi
    cd  ${HUMHUB_DIR}/protected/vendor/yiisoft/yii2/helpers
    aws s3 cp s3://${S3_BUCKET}/BaseFileHelper.php .
    sed -i 's/getenv("HUMHUB_AWS_S3_BUCKET")/"'${HUMHUB_AWS_S3_BUCKET}'"/g' BaseFileHelper.php
    sed -i 's/getenv("HUMHUB_AWS_S3_UPLOAD_DIRECTORY")/"'$(echo ${HUMHUB_AWS_S3_UPLOAD_DIRECTORY} | sed 's/\//\\\//g')'"/g' BaseFileHelper.php
 
    
fi





tmp_cronfile=$(mktemp)

echo "* * * * * /usr/bin/php ${HUMHUB_DIR}/protected/yii queue/run >/dev/null 2>&1" >> "$tmp_cronfile"
echo "* * * * * /usr/bin/php ${HUMHUB_DIR}/protected/yii cron/run >/dev/null 2>&1" >> "$tmp_cronfile"

# Carregue o arquivo temporário no crontab do usuário www-data
sudo crontab -u www-data "$tmp_cronfile"

# Remova o arquivo temporário
rm "$tmp_cronfile"

echo "Tarefas adicionadas ao crontab do usuário www-data."

echo '' > ~/.bash_history