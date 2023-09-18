#!/bin/bash


latest_stunnel_version='stunnel-5.70'

cd ~
git clone https://github.com/aws/efs-utils
cd ./efs-utils
chmod +x ./build-deb.sh
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
sudo apt-get -y install wget
if echo $(python3 -V 2>&1) | grep -e "Python 3.6"; then
    sudo wget https://bootstrap.pypa.io/pip/3.6/get-pip.py -O /tmp/get-pip.py
elif echo $(python3 -V 2>&1) | grep -e "Python 3.5"; then
    sudo wget https://bootstrap.pypa.io/pip/3.5/get-pip.py -O /tmp/get-pip.py
elif echo $(python3 -V 2>&1) | grep -e "Python 3.4"; then
    sudo wget https://bootstrap.pypa.io/pip/3.4/get-pip.py -O /tmp/get-pip.py
else
    sudo apt-get -y install python3-distutils
    sudo wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
fi
sudo python3 /tmp/get-pip.py
sudo pip3 install botocore
sudo /usr/local/bin/pip3 install --target /usr/lib/python3/dist-packages botocore

#   sudo pip3 install botocore --upgrade

sudo apt-get install build-essential libwrap0-dev libssl-dev
sudo curl -o ${latest_stunnel_version}.tar.gz https://www.stunnel.org/downloads/${latest_stunnel_version}.tar.gz
sudo tar xvfz ${latest_stunnel_version}.tar.gz
cd ${latest_stunnel_version}
sudo ./configure

sudo make
sudo rm /bin/stunnel
sudo make install
sudo ln -s /usr/local/bin/stunnel /bin/stunnel

# sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_DNS}:/   ${HUMHUB_DIR}/protected

echo "${EFS_DNS}:/ ${HUMHUB_DIR}/protected nfs nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" | sudo tee -a /etc/fstab
mount -a