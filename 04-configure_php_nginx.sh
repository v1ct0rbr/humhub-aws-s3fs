#!/bin/bash

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