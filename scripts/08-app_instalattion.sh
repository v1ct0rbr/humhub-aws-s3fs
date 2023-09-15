#!/bin/bash

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
                    "baseUrl" => "http://'${HUMHUB_DOMAIN}':80"
               
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
    sudo chown -R www-data:www-data ${HUMHUB_DIR}
    # sudo chown -R www-data:www-data ${HUMHUB_DIR}/uploads
    # sudo chown -R www-data:www-data ${HUMHUB_DIR}/protected/modules
    # sudo chown -R www-data:www-data ${HUMHUB_DIR}/protected/config
    # sudo chown -R www-data:www-data ${HUMHUB_DIR}/protected/runtime
    # sudo chown www-data:www-data ${HUMHUB_DIR}/protected/config/dynamic.php
    
    
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
        echo "sudo s3fs \"$HUMHUB_AWS_S3_BUCKET\" \"${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}\" -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp" | sudo tee -a /etc/fstab
        sudo s3fs "$HUMHUB_AWS_S3_BUCKET" "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp
       
    fi
    cd  ${HUMHUB_DIR}/protected/vendor/yiisoft/yii2/helpers
    aws s3 cp s3://${S3_BUCKET}/BaseFileHelper.php .
    sed -i 's/getenv("HUMHUB_AWS_S3_BUCKET")/"'${HUMHUB_AWS_S3_BUCKET}'"/g' BaseFileHelper.php
    sed -i 's/getenv("HUMHUB_AWS_S3_UPLOAD_DIRECTORY")/"'$(echo ${HUMHUB_AWS_S3_UPLOAD_DIRECTORY} | sed 's/\//\\\//g')'"/g' BaseFileHelper.php
 
    
fi