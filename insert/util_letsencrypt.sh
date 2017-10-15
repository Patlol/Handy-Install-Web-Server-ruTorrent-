
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
if [[ $installCert =~ ^[YyNn]$ ]]; then
  ## Certificat letsencript avec certbot
  echo
  echo "******************************************************************"
  echo "|   Let's Encrypt obtain and install HTTPS/TLS/SSL certificates  |"
  echo "|            replacing the self-signed certificate               |"
  echo "******************************************************************"
  echo
  sleep 1
  if [[ $nameDistrib == "Debian" && $os_version_M -eq 8 ]]; then
    chmod 777 /etc/apt/sources.list
    echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
    chmod 644 /etc/apt/sources.list
    apt-get update
    cmd="apt-get -t jessie-backports install -yq python-certbot-apache"; $cmd || __msgErreurBox "$cmd" $?
  elif [[ $nameDistrib == "Debian" && $os_version_M -eq 9 ]]; then
    apt-get update
    cmd="apt-get install -yq python-certbot-apache"; $cmd || __msgErreurBox "$cmd" $?
  else
    apt-get install software-properties-common
    add-apt-repository -y ppa:certbot/certbot
    apt-get update
    cmd="apt-get install -yq python-certbot-apache"; $cmd || __msgErreurBox "$cmd" $?
  fi
  cmd="certbot --apache certonly -d $__saisieDomaineBox1 -d $__saisieDomaineBox2"; $cmd || __msgErreurBox "$cmd" $?
  if [[ $? -ne 0 ]]; then
    __messageBox "Let's Encrypt install" "
      ${BO}There are a issue on cerbot:${N}
      Domain: $__saisieDomaineBox1
      We can't continue to install Let's Encrypt.
      ${R}ServerName in Apache site-config deleted${N}"
    sed -i "s/ServerName "$__saisieDomaineBox1"/# &/g" $REPAPA2/sites-available/000-default.conf
    sed -i "s/ServerAlias "$__saisieDomaineBox2"/# &/g" $REPAPA2/sites-available/000-default.conf
    __servicerestart "apache2"
    apt-get purge -yq certbot
    continue  # retour au menu principal
  else
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

    ## Modif ownCloud : domaines approuvés
    pathOCC=$(find /var -name occ 2>/dev/null)
    if [[ -n $pathOCC ]]; then
      sed -i "/1 => '"$IP"'/a \2 => '"$__saisieDomaineBox1"',\n3 => '"$__saisieDomaineBox2"', " $ocpath/config/config.php
      echo
      echo "*********************************************************"
      echo "|   Domain name added in owncloud trusted domain array  |"
      echo "*********************************************************"
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
    for (( i = 0; i < 2; i++ )); do
      certbot renew --dry-run
      if [[ $? -ne 0 ]] && [[ i -eq 0 ]];then
        echo
        echo "There are a issue with renew running"
        echo "The installed cert are:"
        certbot certificates
        echo -ne "/!\ You will not have cron task to renew your certificate Let's Encrypt\nit expires in 90 days"
        echo
        if [[ $i -eq 0 ]];then
          echo "We retested the simulation. Wait. "
          sleep 3
        fi
        sleep 3
      else
        echo
        echo "*********************************************"
        echo "|    Renewing all existing certificates     |"
        echo "|       it's ok. We add on cron task        |"
        echo "|   The cert are renewing all the 60 days   |"
        echo "*********************************************"
        echo
        sleep 1
        sed -i 's/# renew_before_expiry = 30 days/renew_before_expiry = 30 days/' /etc/letsencrypt/renewal/$__saisieDomaineBox1.conf
        cp $REPLANCE/insert/letsencrypt-cron.sh /etc/letsencrypt/letsencrypt-cron.sh
        chmod 755 /etc/letsencrypt/letsencrypt-cron.sh
        cp $REPLANCE/fichiers-conf/letsencrypt-hiwst
        __servicerestart "cron"
        codeSortie1=$?
        cp $REPLANCE/fichiers-conf/letsencrypt-rotate /etc/logrotate.d/letsencrypt-rotate
        logrotate -f /etc/logrotate.conf
        codeSortie2=$(( $? + $codeSortie1 ))
        if [[ $codeSortie2 -eq 0 ]]; then
          echo
          echo "****************************************"
          echo "|         Renew cron task and          |"
          echo "|  logrotate of letsencrypt-cron.log   |"
          echo "|                 ok                   |"
          echo "****************************************"
          echo
        else
          echo
          echo "****************************************"
          echo "|         WARNING ! Issue on           |"
          echo "|       Renew cron task and/or         |"
          echo "|  logrotate of letsencrypt-cron.log   |"
          echo "****************************************"
          echo
          sleep 2
        fi  # logrotate ok
        sleep 3
        break  # sort de la boucle double test
      fi  # cerbot renew ok
    done  # fin de la boucle double test
  fi  # install cert by certbot ok
fi  # installCert = Y
