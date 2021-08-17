#! /bin/bash

systemctl stop firewalld
systemctl disable firewalld
setenforce 0

dnf makecache
dnf install httpd httpd-tools git -y

git clone https://github.com/ethicalhack3r/DVWA /var/www/html/
cp /var/www/html/config/config.inc.php.dist /var/www/html/config/config.inc.php
sed -i 's/p@ssw0rd/${ADMIN-PASSWORD}/' /var/www/html/config/config.inc.php

cat <<-EOL | tee /var/www/html/init-jump.ps1
Set-NetFirewallProfile -All -Enabled False
Set-MpPreference -DisableRealtimeMonitoring \$true
New-Item -itemtype directory -path "c:\" -name "www"
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install googlechrome mobaxterm -y --ignore-checksum
\$keycontent=@"
${PRIV-KEY}
"@

Set-Content -Path c:\www\ssh_key.pem -Value \$keycontent

Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${CENTOS-PRIV-IP} centos2"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${KALI-PRIV-IP} attacker"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${DVWA-PRIV-IP} dvwa"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${JUMP-PRIV-IP} web"

\$progressPreference = "silentlyContinue"
Invoke-Expression "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
Invoke-WebRequest -Uri "https://www.ritlabs.com/download/tinyweb/tinyweb-1-94.zip" -Outfile "C:\www\tinyweb.zip"
Invoke-WebRequest -Uri "https://github.com/trendlabs/2021Q3HOL-Azure-Infra/blob/main/data/dnscat.sh?raw=true" -Outfile "C:\www\dnscat.sh"
Expand-Archive -Path C:\www\tinyweb.zip -DestinationPath C:\www -Force
\$html_code=@"
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>HOL-AMEA-2021-Q3</title>
</head>

<body>

<p>
  This is a sample page
  <br> Web Server Public IP: ${JUMP-PUB-IP}
  <br> Web Server Private IP: ${JUMP-PRIV-IP}
</p>

</body>
</html>
"@
Set-Content -Path c:\www\index.html -Value \$html_code
c:\www\tiny c:\www

EOL

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

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos2" >> /etc/hosts

cat <<-EOL | tee /home/${ADMIN-USER}/ssh_key.pem
${PRIV-KEY}
EOL

chmod 400 /home/${ADMIN-USER}/ssh_key.pem
chown -R ${ADMIN-USER}:${ADMIN-USER} /home/${ADMIN-USER}
echo "alias ssh='ssh -i /home/labadmin/ssh_key.pem'" >> /etc/bashrc
source /etc/bashrc
until ping -c1 centos2 >/dev/null 2>&1; do :; done
sleep 30
sudo -H -u ${ADMIN-USER} bash -c 'ssh -o "StrictHostKeyChecking no" ${ADMIN-USER}@centos2 date'
