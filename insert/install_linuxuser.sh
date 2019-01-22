##############################
#  Création de linux user    #
##############################
salt=$(perl -e '@c=("A".."Z","a".."z",0..9);print join("",@c[map{rand @c}(1..2)])')
pwCrypt=$(perl -e 'print crypt($ARGV[0], $ARGV[1])' $pwLinux $salt)
cmd="useradd -m -G adm,dip,plugdev,www-data,sudo -p $pwCrypt $userLinux"; $cmd || __msgErreurBox "$cmd" $?
if [[ $? -ne 0 ]]; then
  __messageBox "Linux user" "
    Unable to create linux user
    "
  exit 1
fi
sed -i "1 a\bash" /home/$userLinux/.profile  #ubuntu ok, debian ok après reboot
echo $userLinux > $REPLANCE/firstusers
readonly REPUL="/home/$userLinux"
cmd="usermod -aG www-data $userLinux"; $cmd ||  __msgErreurBox "$cmd" $?

## config mc (installé dans install_apache.sh)
# config mc user
mkdir -p $REPUL/.config/mc/
cp ${REPLANCE}/fichiers-conf/mc_panels.ini $REPUL/.config/mc/panels.ini
chown -R $userLinux:$userLinux $REPUL/.config/
# config mc root
mkdir -p /root/.config/mc/
cp ${REPLANCE}/fichiers-conf/mc_panels.ini /root/.config/mc/panels.ini

echo
echoc v "                              "
echoc v "     Linux user created       "
echoc v "                              "
sleep 1
echo
