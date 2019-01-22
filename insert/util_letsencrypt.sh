# Saisie nom de domaine et installation certificat (y,n) check
# Depend : __messageBox  __ouinonBox
# ARG : titre, texte, lignes sous-boite
# RETURN : $__saisieDomaineBox1, $__saisieDomaineBox2 (www.), $installCert (y|Y|n|N)
__saisieDomaineBox() {
  local reponse=""; local message=""; local inputItem=""
  installCert="Y"  # retournée à l'appelant
  __saisieDomaineBox1=""; __saisieDomaineBox2=""   # retournée à l'appelant
  until false; do
    until false; do
      CMD=(dialog --aspect $RATIO --colors --backtitle "$TITRE" --title "${1}" --separator "\\" --default-item "$inputItem" --trim --cr-wrap --mixedform "${2}" 0 0 ${3} "Domain name:" 1 2 "$__saisieDomaineBox1" 1 28 44 43 0 "Cert Let's Encrypt [Y/N]:" 3 2 "$installCert" 3 28 2 1 0)
      reponse=$("${CMD[@]}" 2>&1 > /dev/tty)  # ezfezf.ff\Y\
      if [[ $? == 1 ]]; then return 1; fi  # bouton cancel
      __saisieDomaineBox1=$(echo $reponse | awk -F"\\" '{ print $1 }')
      installCert=$(echo $reponse | awk -F"\\" '{ print $2 }')
      if [[ "$__saisieDomaineBox1" =~ ^([[:digit:]a-z-]+\.[a-z\.]{2,})$ ]] && \
      [[ $(echo $__saisieDomaineBox1 | grep -E "^w{3}\.") == "" ]]; then
        __saisieDomaineBox2="www.$__saisieDomaineBox1"
        break
      else
                __messageBox "Entry validation" "
          Enter a valid domain name.
          Only unaccented alphanumeric characters,
          without http(s):// and www."
          inputItem="Domain name:"
      fi
      if [[ ! $installCert =~ ^[YyNn]$ ]]; then
        __messageBox "Entry validation" "
          Enter a valid reply:
          Y y N n in \"Cert Let's Encrypt\""
        installCert="Y"
        inputItem="Cert Let's Encrypt [Y/N]:"
      fi
    done  # fin saise
    if [[ $installCert =~ ^[Yy]$ ]]; then message="${BO}Vous allez installer Let'sEncrypt${N}"; fi
    __ouinonBox "Confirmation" " The domain names concerned are well:
      ${R}$__saisieDomaineBox1${N}
      and
      ${R}$__saisieDomaineBox2${N}
      $message"
    if [[ $__ouinonBox -eq 0 ]]; then break; fi
  done  # fin confirmation
} # fin __saisieDomaineBox()

__saisieDomaineBox "Domain name registration" "
  If you have provided a domain name for ${IP}/ruTorrent /ownCloud
  ${R}AND${N} the DNS servers are uptodate, enter here your domain name.

  This domain will be used for the ${BO}Apache${N} and ${BO}Let's Encrypt${N} (free ssl certificate) configuration.

  Example: ${I}my-domain-name.co.uk${N} or ${I}22my-22domaine-name.commmm${N} etc. ...

  ${R}Do not enter www. or http:// The two domains ${BO}www.mydomainname.com${N}${R}
  and ${BO}mydomainname.com${N}${R} will be automatically used${N}" 3

if [[ $? -ne 0 ]]; then   # cancel __saisieDomaineBox partie Saisie
  continue  # retour main menu
fi

domainName=$__saisieDomaineBox1
domainName2=$__saisieDomaineBox2

## Modif apache
# ServerName xxxx.xx   $domainName
# ServerAlias www.xxxx.xx   $domainName2
sed -i "/<VirtualHost/a \ServerName "$domainName"\nServerAlias "$domainName2"\n" $REPAPA2/sites-available/000-default.conf
__servicerestart "apache2"
echo
echoc v "                                                                 "
echoc v "              ServerName in Apache site-config added             "
echoc v "                                                                 "
echo
sleep 2

## Modif ownCloud : domaines approuvés
pathOCC=$(find /var -name occ 2>/dev/null)
if [[ -n "$pathOCC" ]]; then
  sed -i "/1 => '"$IP"'/a \2 => '"$domainName"',\n3 => '"$domainName2"', " $ocpath/config/config.php
  echo
  echoc v " Domain name added in owncloud trusted domain array "
  echo
fi

## Install let's encrypt
if [[ $installCert =~ ^[YyNn]$ ]]; then
  ## Certificat letsencript avec certbot
  echo
  echoc v "                                                                 "
  echoc v "   Let's Encrypt obtain and install HTTPS/TLS/SSL certificates   "
  echoc v "             replacing the self-signed certificate               "
  echoc v "                                                                 "
  echo
  sleep 1
  if [[ "$nameDistrib" == "Debian" && $os_version_M -eq 8 ]]; then
    chmod 777 /etc/apt/sources.list
    echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
    chmod 644 /etc/apt/sources.list
    apt-get update
    cmd="apt-get -t jessie-backports install -yq python-certbot-apache"; $cmd || __msgErreurBox "$cmd" $?
  elif [[ "$nameDistrib" == "Debian" && $os_version_M -eq 9 ]]; then
    apt-get update
    cmd="apt-get install -yq python-certbot-apache"; $cmd || __msgErreurBox "$cmd" $?
  else
    apt-get install software-properties-common
    add-apt-repository -y ppa:certbot/certbot
    apt-get update
    cmd="apt-get install -yq python-certbot-apache"; $cmd || __msgErreurBox "$cmd" $?
  fi
  cmd="certbot --apache certonly -d $domainName -d $domainName2"; $cmd || __msgErreurBox "$cmd" $?
  if [[ $? -ne 0 ]]; then
    __messageBox "Let's Encrypt install" "
      ${BO}There are a issue on cerbot:${N}
      Domain: $domainName
      We can't continue to install Let's Encrypt.
      ${R}ServerName in Apache site-config deleted${N}"
    sed -i "s/ServerName "$domainName"/# &/g" $REPAPA2/sites-available/000-default.conf
    sed -i "s/ServerAlias "$domainName2"/# &/g" $REPAPA2/sites-available/000-default.conf
    __servicerestart "apache2"
    apt-get purge -yq certbot
    continue  # retour au menu principal
  fi
  certbot certificates
  sleep 2
  ## Modif la config ssl dans apache
  sed -i -e 's|\(SSLCertificateFile.*/etc/ssl/certs/ssl-cert-snakeoil.pem\)|# &|'       -e 's|SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key|# &|' $REPAPA2/sites-available/default-ssl.conf
  sed -i -e '/<Location \/rutorrent>/i\ SSLCertificateFile \/etc\/letsencrypt\/live\/'$domainName'\/fullchain.pem\n SSLCertificateKeyFile \/etc\/letsencrypt\/live\/'$domainName'\/privkey.pem\n Include \/etc\/letsencrypt\/options-ssl-apache.conf\n\n'       $REPAPA2/sites-available/default-ssl.conf

  sed -i '/<\/VirtualHost>/i\ RewriteEngine On\n RewriteCond %{SERVER_NAME} ='$domainName' [OR] \n RewriteCond %{SERVER_NAME} ='$domainName2' \n RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent] \n' $REPAPA2/sites-available/000-default.conf

  __servicerestart "apache2"

    echo
    echoc v " SSL Apache config modified "
    echo
    sleep 2

  ## Modif webmin
  if [[ -e /etc/webmin ]]; then
    repWebmin="/etc/webmin"
    cp $repWebmin/miniserv.conf $repWebmin/miniserv.conf-dist
    sed -i "s|keyfile=/etc/webmin/miniserv.pem|keyfile=/etc/letsencrypt/live/"$domainName"/privkey.pem|" $repWebmin/miniserv.conf
    echo -e "extracas=\ncipher_list_def=1\nssl_redirect=0\ncertfile=/etc/letsencrypt/live/$domainName/cert.pem\nno_tls1_2=" >> $repWebmin/miniserv.conf

    __servicerestart "webmin"

    echo
    echoc v " Webmin SSL certificate modified "
    echo
    sleep 1
  fi

  ## Renew
  echoc v "                                            "
  echoc v "     Renewing all existing certificates     "
  echoc v "   just a simulating renewal from dry run   "
  echoc v "          This may take a while             "
  echoc v "                                            "
  echo
  for (( i = 0; i < 2; i++ )); do
    certbot renew --dry-run
    if [[ $? -ne 0 ]] && [[ $i -eq 0 ]];then
      if [[ $i -eq 0 ]];then
        echo
        echoc r "                                          "
        echoc r "   There are a issue with renew running   "
        echoc r "        The installed cert are:           "
        echoc r "    We retested the simulation. Wait.     "
        echoc r "                                          "
        sleep 3
      else
        certbot certificates
        echo
        echoc r "                                                                             "
        echoc r "   /!\ You will not have cron task to renew your certificate Let's Encrypt   "
        echoc r "                         it expires in 90 days                               "
        echoc r "                                                                             "
        echo
      fi
      sleep 3
    else
      echo
      echoc v "                                           "
      echoc v "    Renewing all existing certificates     "
      echoc v "       it's ok. We add on cron task        "
      echoc v "   The cert are renewing all the 60 days   "
      echoc v "                                           "
      echo
      sleep 1
      sed -i 's/# renew_before_expiry = 30 days/renew_before_expiry = 30 days/' /etc/letsencrypt/renewal/$domainName.conf
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
        echoc v "                                       "
        echoc v "         Renew cron task and           "
        echoc v "   logrotate of letsencrypt-cron.log   "
        echoc v "             All is ok                 "
        echoc v "                                       "
        echo
      else
        echo
        echoc r "                                       "
        echoc r "          WARNING ! Issue on           "
        echoc r "        Renew cron task and/or         "
        echoc r "   logrotate of letsencrypt-cron.log   "
        echoc r "                                       "
        echo
        sleep 2
      fi  # logrotate ok
      sleep 3
      break  # sort de la boucle double test
    fi  # cerbot renew ok
  done  # fin de la boucle double test
# install cert by certbot ok
cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

Certificate is installed with Let's Encrypt
    Domaines names: $domainName and
                    $domainName2
EOF

fi  # installCert = Y

cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

Apache2 and ownCloud (if installed) conigured for
    Domaines names: $domainName and
                    $domainName2
EOF
