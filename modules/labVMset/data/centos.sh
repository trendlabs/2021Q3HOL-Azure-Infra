#! /bin/bash

dnf update -y
dnf makecache
dnf install python3 python3-pip epel-release ansible -y
pip install pywinrm

systemctl stop firewalld
systemctl disable firewalld

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos-2" >> /etc/hosts

cat <<-EOL | tee /home/${ADMIN-USER}/ssh_key.pem
${PRIV-KEY}
EOL
chmod 400 /home/${ADMIN-USER}/ssh_key.pem

mkdir /home/${ADMIN-USER}/ansible
cd  /home/${ADMIN-USER}/ansible
cat <<-EOL | tee ansible_hosts
[web]
${JUMP-PRIV-IP}

[web:vars]
ansible_user=${ADMIN-USER}
ansible_password=${ADMIN-PASSWORD}
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
EOL

cat <<-EOL | tee init-jump.yaml
---
# This playbook tests the script module on Windows hosts

- name: Run powershell script
  hosts: web
  gather_facts: false
  tasks:
    - name: Run powershell script
      script: init-jump.ps1
EOL

cat <<-EOL | tee init-jump.ps1
New-Item -itemtype directory -path "c:\" -name "www"
Set-NetFirewallProfile -All -Enabled False
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
choco install googlechrome mobaxterm -y --ignore-checksum
\$keycontent=@"
${PRIV-KEY}
"@

Set-Content -Path c:\www\ssh_key.pem -Value \$keycontent

Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${CENTOS-PRIV-IP} centos-2"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${KALI-PRIV-IP} attacker"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${DVWA-PRIV-IP} dvwa"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${JUMP-PRIV-IP} web"

\$progressPreference = "silentlyContinue"
Invoke-Expression "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
Invoke-WebRequest -Uri "https://www.ritlabs.com/download/tinyweb/tinyweb-1-94.zip" -Outfile "C:\www\tinyweb.zip"
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
  <br> Your public IP: ${JUMP-PUB-IP}
  <br> Your private IP: ${JUMP-PRIV-IP}
</p>

</body>
</html>
"@
Set-Content -Path c:\www\index.html -Value \$html_code
c:\www\tiny c:\www

EOL
