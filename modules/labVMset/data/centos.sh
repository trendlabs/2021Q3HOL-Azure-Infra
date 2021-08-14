#! /bin/bash

systemctl stop firewalld
systemctl disable firewalld

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos-2" >> /etc/hosts

cd /home/${ADMIN-USER}
cat <<-EOL | tee ssh_key.pem
${PRIV-KEY}
EOL
chmod 400 ssh_key.pem
