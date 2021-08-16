Your Resource Group Name: ${RG-NAME}
Your Resource Group Location: ${RG-LOCATION}

1. Jump public IP list:
${JUMP-IP-LIST}

2. Jump RDP Account
- Username: ${ADMIN-USER}
- Password: ${ADMIN-PASSWORD}

3. SSH Key:
- in Jump: c:\www\ssh_key.pem
- in Linux: $HOME/ssh_key.pem

4. Access VMs:
- In the VMs you can access other VMs by following names (already registered in the  VM hosts files )
  . "attacker" --> Kali machine
  . "web" --> Jump machine where we will put the generated payload for download
  . "centos2" --> CentOS machine which need to be protected
  . "dvwa" --> Web Application machine which need to be protected

- open MobaXterm \ Sessions to create new sessions
  . choose SSH to create SSH connection to VMs
  . Remote Host: put in a desired name above
  . Specify user: ${ADMIN-USER}
  . In the Advanced SSH Settings tab, select "Use private key" and choose key at c:\www\ssh_key.pem

5. DVWA access:
- in Jump VM, you open Chrome and browse to http://dvwa
- username: admin
- password: password
