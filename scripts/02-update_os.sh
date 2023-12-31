#!/bin/bash

echo 'Instalando dependências..................................................1%'

sudo apt update -y 

sudo apt upgrade -y

sudo apt install -y php php-cli \
php-imagick php-curl php-bz2 php-gd php-intl php-mbstring \
php-mysql php-zip php-apcu php-xml php-ldap composer python3 jq ca-certificates s3fs fuse binutils

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
    rm awscliv2.zip
fi

sudo apt autoremove -y