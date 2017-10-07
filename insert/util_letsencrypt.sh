
## Modif apache
# ServerName xxxx.xx   $__saisieDomaineBox1
# ServerAlias www.xxxx.xx   $__saisieDomaineBox2
sed -i "/<VirtualHost/a \ServerName "$__saisieDomaineBox1"\nServerAlias "$__saisieDomaineBox2"\n" $REPAPA2/sites-available/000-default.conf
__servicerestart "apache2"
echo
echo "**********************************************"
echo "|   ServerName in Apache site-config added   |"
echo "**********************************************"
echo
sleep 2

## Modif ownCloud : domaines approuvés
pathOCC=$(find /var -name occ 2>/dev/null)
if [[ -n $pathOCC ]]; then
  sed -i "/1 => '"$IP"'/a \2 => '"$__saisieDomaineBox1"',\n3 => '"$__saisieDomaineBox2"', " $ocpath/config/config.php
fi
echo
echo "*********************************************************"
echo "|   Domain name added in owncloud trusted domain array  |"
echo "*********************************************************"
echo
sleep 2

## Certificat letsencript avec certbot
echo
echo "******************************************************************"
echo "|   Let's Encrypt obtain and install HTTPS/TLS/SSL certificates  |"
echo "|            replacing the self-signed certificate               |"
echo "******************************************************************"
echo
sleep 1
apt-get update
cmd="sudo apt-get install -yq python-certbot-apache"; $cmd || __msgErreurBox $cmd $?
certbot --apache certonly -d $__saisieDomaineBox1 -d $__saisieDomaineBox2
certbot certificates
sleep 2

## Modif la config ssl dans apache
sed -i -e 's|\(SSLCertificateFile.*/etc/ssl/certs/ssl-cert-snakeoil.pem\)|# &|'       -e 's|SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key|# &|' $REPAPA2/sites-available/default-ssl.conf
sed -i -e '/<Location \/rutorrent>/i\ SSLCertificateFile \/etc\/letsencrypt\/live\/'$__saisieDomaineBox1'\/fullchain.pem\n SSLCertificateKeyFile \/etc\/letsencrypt\/live\/'$__saisieDomaineBox1'\/privkey.pem\n Include \/etc\/letsencrypt\/options-ssl-apache.conf\n\n'       $REPAPA2/sites-available/default-ssl.conf

sed -i '/<\/VirtualHost>/i\ RewriteEngine On\n RewriteCond %{SERVER_NAME} ='$__saisieDomaineBox1' [OR] \n RewriteCond %{SERVER_NAME} ='$__saisieDomaineBox2' \n RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent] \n' $REPAPA2/sites-available/000-default.conf

__servicerestart "apache2"

  echo
  echo "**********************************"
  echo "|   SSL Apache config modified   |"
  echo "**********************************"
  echo
  sleep 2

## Modif webmin
if [[ -e /etc/webmin ]]; then
  repWebmin="/etc/webmin"
  cp $repWebmin/miniserv.conf $repWebmin/miniserv.conf-dist
  sed -i -e "s/no_ssl2=1/no_ssl2=/" -e "s/no_ssl3=1/no_ssl3=/" -e "s/no_tls1=1/no_tls1=/" $repWebmin/miniserv.conf
  sed -i "s|keyfile=/etc/webmin/miniserv.pem|keyfile=/etc/letsencrypt/live/"$__saisieDomaineBox1"/privkey.pem|" $repWebmin/miniserv.conf
  echo -e "extracas=\ncipher_list_def=1\nssl_redirect=0\ncertfile=/etc/letsencrypt/live/$__saisieDomaineBox1/cert.pem\nno_tls1_2=" >> $repWebmin/miniserv.conf

  __servicerestart "webmin"

  echo
  echo "***************************************"
  echo "|   Webmin SSL certificate modified   |"
  echo "***************************************"
  echo
  sleep 2
fi

echo
echo "*********************************************"
echo "|    Renewing all existing certificates     |"
echo "|  just a simulating renewal from dry run   |"
echo "|          This may take a while            |"
echo "*********************************************"
echo
certbot renew --dry-run
if [[ $? -ne 0 ]];then
  echo "There are a issue with renew running"
  echo "The installed cert are:"
  certbot certificates
  echo -ne "/!\ You will not have cron task to renew your certificate Let's Encrypt\nit expires in 90 days"
  read
else
  echo
  echo "*********************************************"
  echo "|    Renewing all existing certificates     |"
  echo "|       it's ok. We add on cron task        |"
  echo "|   The cert are renewing all the 30 days   |"
  echo "*********************************************"
  echo
  sleep 1
  sed -i 's/# renew_before_expiry = 30 days/renew_before_expiry = 30 days/' /etc/letsencrypt/renewal/$__saisieDomaineBox1.conf
  chmod 755 $REPLANCE/insert/letsencrypt-cron.sh
  cp $REPLANCE/insert/letsencrypt-cron.sh /etc/cron.daily/letsencrypt-cron.sh
  __servicerestart "cron"
  if [[ $? -eq 0 ]]; then
    echo
    echo "********************"
    echo "|   cron task ok   |"
    echo "********************"
    echo
  fi
fi
sleep 3
