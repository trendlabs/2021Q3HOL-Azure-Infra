#! /bin/bash

dnf update -y
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce --nobest -y
systemctl start docker
systemctl enable docker
dnf install git ruby ruby-devel rubygems make gcc redhat-rpm-config -y

usermod -aG docker ${ADMIN-USER}

echo "${KALI-PRIV-IP} attacker" >> /etc/hosts
echo "${DVWA-PRIV-IP} dvwa" >> /etc/hosts
echo "${JUMP-PRIV-IP} web" >> /etc/hosts
echo "${CENTOS-PRIV-IP} centos2" >> /etc/hosts

service systemd-resolved stop
systemctl disable systemd-resolved
systemctl stop firewalld
systemctl disable firewalld

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

cd /home/${ADMIN-USER}

git clone https://github.com/iagox86/dnscat2.git
cd dnscat2/server/
gem install bundler
mv /home/${ADMIN-USER}/bin/bundle* /usr/local/bin/
ln -s /usr/local/bin/bundle /usr/bin/bundle
ln -s /usr/local/bin/bundler /usr/bin/bundler
bundle install

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

cd /home/${ADMIN-USER}

mkdir /home/${ADMIN-USER}/.msf4

curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod +x msfinstall
./msfinstall

msfdb init --use-defaults --component database
msfdb init --use-defaults --component webservice
chown -R ${ADMIN-USER}:${ADMIN-USER} /home/${ADMIN-USER}/
sudo -H -u ${ADMIN-USER} bash -c 'msfdb init --use-defaults --component database'
sudo -H -u ${ADMIN-USER} bash -c 'msfdb init --use-defaults --component webservice'

cat <<-EOL | tee ssh_key.pem
${PRIV-KEY}
EOL

chmod 400 ssh_key.pem
echo "alias ssh='ssh -i /home/labadmin/ssh_key.pem'" >> /etc/bashrc
source /etc/bashrc
