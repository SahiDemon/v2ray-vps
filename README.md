# vps-4-v2ray
 Installing VPS in ubuntu server for v2ray host

Manage Script

## :heavy_exclamation_mark: Requirements

* Vps with Ubuntu 20.04 or Ubuntu-latest OS.
* domain

Go to [DUCKDNS](https://www.duckdns.org/) and create a domain
------------------------------------------
## :book: Installation - Without DNS

Run Full autmated script 
```
bash <(curl -s "https://raw.githubusercontent.com/SahiDemon/v2ray-vps/refs/heads/main/main.sh")

```


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


