clear
echo
echoc r "                                        "
echoc b "           Installing WebMin            "
echoc r "         This may take a while          "
echoc r "                                        "
echo
# paquets debian 8
upDebWebMinD="http://prdownloads.sourceforge.net/webadmin/webmin_1.850_all.deb"
paquetWebMinD="perl libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinD="webmin_1.850_all.deb"
# paquets debian 9
upDebWebMinD9="http://prdownloads.sourceforge.net/webadmin/webmin_1.850_all.deb"
paquetWebMinD9="perl libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinD9="webmin_1.850_all.deb"
# paquets ubuntu 16
upDebWebMinU="http://prdownloads.sourceforge.net/webadmin/webmin_1.850_all.deb" # "http://www.webmin.com/download/deb/webmin-current.deb"
paquetWebMinU="perl libnet-ssleay-perl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinU="webmin_1.850_all.deb" # "webmin-current.deb"

cd /tmp
# idem pour les 3 distrib
cmd="wget $upDebWebMinD9"; $cmd || __msgErreurBox "$cmd" $?
cmd="apt-get -f install -y $paquetWebMinD9"; $cmd || __msgErreurBox "$cmd" $?
cmd="dpkg --install $debWebMinD9"; $cmd || __msgErreurBox "$cmd" $?

echoc v "                                                     "
echoc v "                Packages Installed                   "
echoc v "                                                     "
echo
sleep 1


headTest=$(curl -Is http://$IP:10000 | head -n 1)
headTest=$(echo "$headTest" | awk -F" " '{ print $3 }')
if [[ "$headTest" =~ "Document" ]]; then
  echoc v "                                                     "
  echoc v "                  WebMin works well                  "
  echoc v "                                                     "
  echo
  sleep 2
  cat << EOF >> $REPUL/HiwsT/RecapInstall.txt

To access WebMin:
    https://$IP:10000
    ID : root  PW : your root password
    Without Let's Encrypt accept the Self Signed Certificate
    and the exception for this certificate!
EOF
  __messageBox "WebMin installed" " ${I}WebMin works well${N}

    To access WebMin:
    https://$IP:10000
    ID : root  PW : your root password

    Without Let's Encrypt accept the Self Signed Certificate
    and the exception for this certificate!

    This information is added to the file $REPUL/HiwsT/RecapInstall.txt"
else
  __msgErreurBox "curl -Is http://$IP:10000 | head -n 1 | awk -F\" \" '{ print $3 }' renvoie '$headTest'" "http $headTest"
fi
