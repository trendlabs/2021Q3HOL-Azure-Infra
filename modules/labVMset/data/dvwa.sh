#! /bin/bash

dnf update -y
dnf install httpd httpd-tools mariadb-server mariadb php php-fpm php-mysqlnd php-pear git python3 -y

sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/' /etc/php.ini
sed -i 's/allow_url_include = Off/allow_url_include = On/' /etc/php.ini
sed -i 's/display_errors = On/display_errors = Off/' /etc/php.ini

systemctl start httpd
systemctl enable httpd
systemctl start mariadb
systemctl enable mariadb

systemctl start php-fpm
systemctl enable php-fpm

systemctl stop firewalld
systemctl disable firewalld

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

#setsebool -P httpd_execmem 1
# setsebool -P httpd_unified 1
# setsebool -P httpd_can_network_connect 1
# setsebool -P httpd_can_network_connect_db 1

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos-2" >> /etc/hosts

echo "apache ALL=(root) NOPASSWD: /usr/bin/python3" >> /etc/sudoers

cd /home/${ADMIN-USER}

cat <<-EOL | tee ssh_key.pem
${PRIV-KEY}
EOL

chmod 400 /home/${ADMIN-USER}/ssh_key.pem
chown -R ${ADMIN-USER}:${ADMIN-USER} /home/${ADMIN-USER}

mysql -u root -e "CREATE DATABASE IF NOT EXISTS dvwa"
mysql -u root -e "GRANT ALL PRIVILEGES ON dvwa.* to 'dvwa'@'localhost' IDENTIFIED BY '${ADMIN-PASSWORD}'"
mysql -u root -e "FLUSH PRIVILEGES"

git clone https://github.com/ethicalhack3r/DVWA /var/www/html/
cd /var/www/html/config/
cp config.inc.php.dist config.inc.php
sed -i 's/p@ssw0rd/${ADMIN-PASSWORD}/' config.inc.php

chown -R apache:apache /var/www/html

systemctl restart mariadb httpd
