#! /bin/bash

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
setenforce 0

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos2" >> /etc/hosts

cat <<-EOL | tee /home/${ADMIN-USER}/ssh_key.pem
${PRIV-KEY}
EOL

chmod 400 /home/${ADMIN-USER}/ssh_key.pem

echo "alias ssh='ssh -i /home/${ADMIN-USER}/ssh_key.pem'" >> /etc/bashrc
source /etc/bashrc
until ping -c1 centos2 >/dev/null 2>&1; do :; done
sleep 30
sudo -H -u ${ADMIN-USER} bash -c 'ssh -o "StrictHostKeyChecking no" ${ADMIN-USER}@centos2 date'

if ${DVWA}; then
dnf makecache
dnf install httpd httpd-tools git -y

git clone https://github.com/ethicalhack3r/DVWA /var/www/html/
cp /var/www/html/config/config.inc.php.dist /var/www/html/config/config.inc.php
sed -i 's/p@ssw0rd/${ADMIN-PASSWORD}/' /var/www/html/config/config.inc.php

chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd

dnf install mariadb-server mariadb php php-fpm php-mysqlnd php-pear python3 -y
echo "apache ALL=(root) NOPASSWD: /usr/bin/python3" >> /etc/sudoers
sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/' /etc/php.ini
sed -i 's/allow_url_include = Off/allow_url_include = On/' /etc/php.ini
sed -i 's/display_errors = On/display_errors = Off/' /etc/php.ini

systemctl start mariadb
systemctl enable mariadb

systemctl start php-fpm
systemctl enable php-fpm

mysql -u root -e "CREATE DATABASE IF NOT EXISTS dvwa"
mysql -u root -e "GRANT ALL PRIVILEGES ON dvwa.* to 'dvwa'@'localhost' IDENTIFIED BY '${ADMIN-PASSWORD}'"
mysql -u root -e "FLUSH PRIVILEGES"

systemctl restart mariadb httpd
fi
chown -R ${ADMIN-USER}:${ADMIN-USER} /home/${ADMIN-USER}
