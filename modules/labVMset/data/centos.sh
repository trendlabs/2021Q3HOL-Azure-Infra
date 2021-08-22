#! /bin/bash

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos2" >> /etc/hosts

cat <<-EOL | tee /home/${ADMIN-USER}/ssh_key.pem
${PRIV-KEY}
EOL
chmod 400 /home/${ADMIN-USER}/ssh_key.pem

mkdir /home/${ADMIN-USER}/ansible
cat <<-EOL | tee /home/${ADMIN-USER}/ansible/ansible_hosts
[web]
${JUMP-PRIV-IP}

[web:vars]
ansible_user=${ADMIN-USER}
ansible_password=${ADMIN-PASSWORD}
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
EOL

#dnf update -y
dnf makecache
dnf install httpd httpd-tools -y

cat <<-EOL | tee /var/www/html/init-jump.ps1
Set-NetFirewallProfile -All -Enabled False
Set-MpPreference -DisableRealtimeMonitoring \$true
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
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
#Invoke-Expression "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
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

cat <<-EOL | tee /home/${ADMIN-USER}/ansible/init-jump.yaml
---
# This playbook tests the script module on Windows hosts

- name: Run powershell script
  hosts: web
  gather_facts: false
  tasks:
    - name: Run powershell script
      script: init-jump.ps1
EOL

dnf makecache
dnf install php php-fpm php-mysqlnd php-pear python3 python3-pip epel-release -y
pip3 install ansible --user
# until ping -c1 web >/dev/null 2>&1; do :; done
# sleep 30
# ansible-playbook init-jump.yaml -i ansible_hosts > ansible_logs
echo "alias ssh='ssh -i /home/${ADMIN-USER}/ssh_key.pem'" >> /etc/bashrc
source /etc/bashrc
chown -R ${ADMIN-USER}:${ADMIN-USER} /home/${ADMIN-USER}
