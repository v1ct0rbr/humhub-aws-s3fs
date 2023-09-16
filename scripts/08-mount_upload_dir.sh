#!/bin/bash

cd ~
if [ ! -f '~/.passwd-s3fs' ]; then
    echo "$HUMHUB_AWS_KEY_ID:$HUMHUB_AWS_ACCESS_KEY" >~/.passwd-s3fs
    chmod 600 ~/.passwd-s3fs
fi

sudo sed -i '/^#user_allow_other/s/^#//' /etc/fuse.conf
aws s3 sync "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" "s3://$HUMHUB_AWS_S3_BUCKET"

cd  ${HUMHUB_DIR}/protected/vendor/yiisoft/yii2/helpers
aws s3 cp s3://${S3_BUCKET}/BaseFileHelper.php .
sed -i 's/getenv("HUMHUB_AWS_S3_BUCKET")/"'${HUMHUB_AWS_S3_BUCKET}'"/g' BaseFileHelper.php
sed -i 's/getenv("HUMHUB_AWS_S3_UPLOAD_DIRECTORY")/"'$(echo ${HUMHUB_AWS_S3_UPLOAD_DIRECTORY} | sed 's/\//\\\//g')'"/g' BaseFileHelper.php

echo "Setting permissions..."
sudo chown -R www-data:www-data ${HUMHUB_DIR}

sudo s3fs "$HUMHUB_AWS_S3_BUCKET" "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp
