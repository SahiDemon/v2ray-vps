# vps-4-v2ray
 Installing VPS in ubuntu server for v2ray host

Manage Script

## :heavy_exclamation_mark: Requirements

* Vps with Ubuntu 20.04 or Ubuntu-latest OS.
* domain

Go to [DUCKDNS](https://www.duckdns.org/) and create a domain
------------------------------------------
## :book: Installation - Without DNS

Update the Vps
```
apt-get update -y && apt-get upgrade -y
```
restart the server
```
sudo reboot (To restart after the update)
```
Also install curl and socat:
```
apt install curl socat -y
```
Install Acme Script
Download and install the Acme script for getting a free SSL certificate:
```
curl https://get.acme.sh | sh
```
Get Free SSL Certificate
Set the default provider to Let’s Encrypt:
```
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
```
Register your account for a free SSL certificate. In the next command, replace xxxx@xxxx.com by your actual email address:
```
~/.acme.sh/acme.sh --register-account -m xxxx@xxxx.com
```
Obtain an SSL certificate. In the next command, replace host.mydomain.com by your actual host name:
```
~/.acme.sh/acme.sh --issue -d host.mydomain.com --standalone
```
After a minute or so, the script terminates. On success, you will receive feedback as to the location of the certificate and key:

Your cert is in: /root/.acme.sh/host.mydomain.com/host.mydomain.com.cer
Your cert key is in: /root/.acme.sh/host.mydomain.com/host.mydomain.com.key
The intermediate CA cert is in: /root/.acme.sh/host.mydomain.com/ca.cer
And the full chain certs is there: /root/.acme.sh/host.mydomain.com/fullchain.cer
You cannot use the certificate and key in their current locations, as these may be temporary. Therefore install the certificate and key to a permanent location. In the next command, replace host.mydomain.com by your actual host name:
```
~/.acme.sh/acme.sh --installcert -d host.mydomain.com --key-file /root/private.key --fullchain-file /root/cert.crt
```
Install certificate and key issued by Acme script

Run the X-UI Install Script Chinese
```
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
```
Run the X-UI Install Script English
```
bash <(curl -Ls https://raw.githubusercontent.com/NidukaAkalanka/x-ui-english/master/install.sh)
```
------------------------------------------
Private Cert
```
/root/private.key
```


Cert
```
/root/cert.crt
```



## :book: How To Connect
This Script is for automating connect proxy setup

Run in Powershell
```
iwr -useb https://raw.githubusercontent.com/SahiDemon/proxydata/main/ProxyInstall.ps1 | iex
```

Additional resources

Main Repo [REPO PROXYManager](https://github.com/SahiDemon/ProxyManager).
Assets located in its [REPO PROXYDATA](https://github.com/SahiDemon/proxydata).





## :book: Unistallation (Remove xray-core and all modified config files from the server) *will not remove BBR

1) sudo rm  -rf  ~/bash-xray-script

2) sudo git clone https://github.com/SahiDemon/vps-4-v2ray

3) cd vps-4-v2ray

4) sudo chmod 777 remove-xray.sh

5) sudo ./remove-xray.sh


