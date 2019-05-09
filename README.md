# HiwsT
#### bash script for handy installation of a web server with _Apache2 and php_  on fresh Debian 8 and 9 or Ubuntu 16 server

##### We no longer offer Cakebox and nginx: :warning: Cakebox is DEPRECATED <a href="https://github.com/cakebox/cakebox">see here</a> and <a href="https://github.com/cakebox/cakebox/issues/216">here</a> :warning:  

- Creates a Linux user.
- Install apache2.
- Install php5 / php7.0
- Install a self-signed certificate.
- Change the port and user ssh: offers a random ssh port and allows you to modify it if you wish.

![COPIE D'ECRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/HiwsT-intro2.png)  
![COPIE D'ECRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/HiwsT-port.png)  

# HiwsT-util
With this utility you can  
- List users installed on linux, ruTorrent, ownCloud, users who own an openVpn certificate.
- Add Linux + ruTorrent and ownCloud users and thus share your server.  
  - Block the new Linux user has his /home/download from rutorrent  
  - Block the new Linux user has his /home from sftp  
  - Prohibits new Linux user access via ssh and use bash
  - Security ruTorrent with password
  - Add a new ownCloud user with all features (see below)
- Change passwords Linux / ruTorrent
- Delete user Linux + ruTorrent and its directories
- Add a firewall (ufw) and basic rules
- Perform a system status
- Install <a href="https://github.com/Novik/ruTorrent/">ruTorrent</a> and a first user with
  - rtorrent daemon multiuser
  - librtorrent, xmlrpc, mediainfo, ffmpeg, plugin onoff ...
- Add ownCloud ~~10.0.2~~ ~~10.0.3~~ **10.1.1** (optionally with Audioplayer and External storage)
  - With app external storage (for ruTorrent downloads directory or other)
  - and Audioplayer with automatic scanning of new files (iwatch)
- Upgrade an installed ownCloud 10.0.3 => 10.1.1, with backup
- Install / uninstall a VPN (openVPN)
  - Creates / remove new cetificate user
  - Add the necessary iptables rules for openVpn
- Install <a href="http://www.webmin.com/">WebMin</a>
- Install <a href="http://www.phpmyadmin.net/">phpMyAdmin</a>
- Add Let's Encrypt certificate
  - Takes the domain name into apache, ownCloud
  - Creates a certificate with Lets Encrypt / certbot
  - Modifies the certificate on the WebMin server if installed
  - Adds a cron task to renew certificate
- Restart rtorrent service  

![COPIE D'ECRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/HiwsTU-main-menu2.png)  
![COPIE D'ÉCRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/Capture2017-07-02_01:07:57.png)  
![COPIE D'ÉCRAN](https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/png/Capture2017-07-02_01:08:15.png)

Please read <a href="https://github.com/Patlol/Install-Handy-Web-Server-ruTorrent-/wiki/Home">Wiki</a> in french  
Please read <a href="https://github.com/Patlol/Install-Handy-Web-Server-ruTorrent-/wiki/Home-en">Wiki</a> in english

Feedback is welcome. Issues and pull requests can be submitted via GitHub. Fork unrestrained
