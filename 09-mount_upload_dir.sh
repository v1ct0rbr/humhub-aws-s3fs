#!/bin/bash

SCRIPT_BOOT="/home/ubuntu/script_boot.sh"
#sudo s3fs "$HUMHUB_AWS_S3_BUCKET" "${HUMHUB_AWS_S3_UPLOAD_DIRECTORY}" -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp
SERVICE_FILE='/etc/systemd/system/script_boot.service'



if [ ! -f '~/.passwd-s3fs' ]; then
  echo "$HUMHUB_AWS_KEY_ID:$HUMHUB_AWS_ACCESS_KEY" >~/.passwd-s3fs
  sudo chown ubuntu:ubuntu /etc/passwd-s3fs
  chmod 600 ~/.passwd-s3fs
fi

if [ ! -f $SCRIPT_BOOT ]; then

  sudo sed -i '/^#user_allow_other/s/^#//' /etc/fuse.conf
  cd /home/ubuntu
  touch $SCRIPT_BOOT
  echo '#!/bin/bash
s3fs '$HUMHUB_AWS_S3_BUCKET' '$HUMHUB_AWS_S3_UPLOAD_DIRECTORY' -o _netdev,allow_other,nonempty,umask=000,passwd_file=/home/ubuntu/.passwd-s3fs,use_cache=/tmp' >$SCRIPT_BOOT

  chmod +x $SCRIPT_BOOT

  sudo touch service_script_boot
  sudo bash -c 'echo "[Unit]
  Description="s3fs boot service" 
  After=network.target 
       
  [Service]
  Type=simple
  ExecStart=/bin/bash '${SCRIPT_BOOT}'
  TimeoutStartSec=0
            
  [Install]
  WantedBy=default.target" > '$SERVICE_FILE''

  sudo systemctl daemon-reload
  sudo systemctl enable script_boot.service
fi
