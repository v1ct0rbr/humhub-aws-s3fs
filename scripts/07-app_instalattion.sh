#!/bin/bash

if [ -f "${HUMHUB_DIR}/protected/config/dynamic.php" ]; then
    echo "Instalacao existente encontrada!"
    
    cd ${HUMHUB_DIR}/protected/ || exit 1
    if [ "$INSTALLED_VERSION" != "$lastest_humhub_version" ]; then
        echo "Updating from version $INSTALLED_VERSION to $lastest_humhub_version"
        php yii migrate/up --includeModuleMigrations=1 --interactive=0
        php yii search/rebuild
        update_version_file
    fi
else
    echo "No existing installation found!"
    echo "Installing source files..."
    
    update_version_file
    
    
    if [ ! -f "${HUMHUB_DIR}/protected/config/common.php" ]; then
        echo "Generate config using common factory..."
        
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
        echo "Humhub common config is not valid! Fix errors before restarting."
        exit 1
    fi
    
    echo '<?php return
        [
            "controllerMap" => [
                "installer" => "humhub\modules\installer\commands\InstallController"
            ],
            "components" => [
                "urlManager" => [
                    "baseUrl" => "'${HUMHUB_PROTO}'://'${HUMHUB_DOMAIN}'",
                    "hostInfo" => "'${HUMHUB_PROTO}'://'${HUMHUB_DOMAIN}'"
               
                ]
            ]
    ];' > ${HUMHUB_DIR}/protected/config/console.php
    
    php ${HUMHUB_DIR}/protected/config/console.php
    
    
    
    if ! php -l ${HUMHUB_DIR}/protected/config/console.php; then
        echo "Humhub console config is not valid! Fix errors before restarting."
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
        echo "Humhub web config is not valid! Fix errors before restarting."
        exit 1
    fi
    
    
    mkdir -p ${HUMHUB_DIR}/protected/runtime/logs/
    touch ${HUMHUB_DIR}/protected/runtime/logs/app.log
    
    
    
    echo "Começando a instalacao do banco de dados..."
    sleep 2
    cd ${HUMHUB_DIR}/protected/ || exit 1
    echo "Instalando..."
    php yii installer/write-db-config "$HUMHUB_DB_HOST" "$HUMHUB_DB_NAME" "$HUMHUB_DB_USER" "$HUMHUB_DB_PASSWORD"
    php yii installer/install-db
    php yii installer/write-site-config "$HUMHUB_NAME" "$HUMHUB_EMAIL"
    # Set baseUrl if provided
    if [ -n "$HUMHUB_PROTO" ] && [ -n "$HUMHUB_DOMAIN" ]; then
        HUMHUB_BASE_URL="${HUMHUB_PROTO}://${HUMHUB_DOMAIN}"
        echo "Setting base url to: $HUMHUB_BASE_URL"
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
        echo "Setting Mailer configuration..."
        php yii 'settings/set' 'base' 'mailer.transportType' "${HUMHUB_MAILER_TRANSPORT_TYPE}"
        php yii 'settings/set' 'base' 'mailer.hostname' "${HUMHUB_MAILER_HOSTNAME}"
        php yii 'settings/set' 'base' 'mailer.port' "${HUMHUB_MAILER_PORT}"
        php yii 'settings/set' 'base' 'mailer.username' "${HUMHUB_MAILER_USERNAME}"
        php yii 'settings/set' 'base' 'mailer.password' "${HUMHUB_MAILER_PASSWORD}"
        php yii 'settings/set' 'base' 'mailer.encryption' "${HUMHUB_MAILER_ENCRYPTION}"
        php yii 'settings/set' 'base' 'mailer.allowSelfSignedCerts' "${HUMHUB_MAILER_ALLOW_SELF_SIGNED_CERTS}"
    fi
   
      
fi