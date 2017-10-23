# un peu de doc sur l'app updater
# https://doc.owncloud.org/server/latest/admin_manual/maintenance/update.html#set-updating-permissions-label
readonly htuser='www-data'
readonly htgroup='www-data'
readonly rootuser='root'
readonly ocDbName="owncloud"
readonly ocBackup="oc-backup"
readonly ocNewVersion="10.0.3"
# ocpath=/var/www/owncloud

# get infos in config.php
readonly ocDataDir=$(grep "datadirectory" < $ocpath/config/config.php | awk -F"=>" '{ print $2 }' | sed -r "s/[ ',]//g")
readonly ocDataDirRoot=$(echo $ocDataDir | sed 's/\/data\/*$//')

__backupDir() {
  echo
  until false; do
    echo
    echo -en '\E[32mOn your server:\n'
    df -h --output='fstype','size','used','avail','pcent','target' | head -n 1
    df -h --output='fstype','size','used','avail','pcent','target' | grep ext
    echo -e '\E[0m'
    echo -en '\E[31mSize of your data directory:'
    du -sh $ocpath
    echo -en '\E[0m'
    echo
    until false; do
      rep=""
      echo -en "\E[32mDirectory for backup \E[31m(return /$ocBackup)\E[0m "; read __backupDir
      echo
      if [[ $__backupDir == "" ]]; then
        __backupDir="/$ocBackup"
      fi
      __backupDir=$(echo "$__backupDir" | sed -r 's|^[a-zA-Z0-9]|/&|')
      __backupDir=$(echo "$__backupDir" | sed -r 's|/$||')
      echo -en "\E[32mThe backup directory will be \E[31m$__backupDir\E[32m it's ok [y|N]\E[0m "; read rep
      if [[ $rep =~ [Yy] ]]; then break; fi
      echo
    done
    echo
    dataBkupOk=""; rep2=""
    echo -ne "\E[32mDo you want/can backup your data directory? [y|N]\E[0m "; read dataBkupOk
    if [[ $dataBkupOk != [Yy] ]]; then
      break
    else
      echo
      echo -en "\E[32mFor data the backup directory will be \E[31m$__backupDir/data\E[32m it's ok [y|N]\E[0m "; read rep2
      if [[ $rep2 =~ [Yy] ]]; then break; fi
      echo
    fi
  done
}  # return $__backupDir et $dataBkupOk [yY.]

cmd="sudo -u $htuser php $ocpath/occ maintenance:mode --on"; $cmd || __msgErreurBox "$cmd" $?

echo
echoc v " Turned on maintenance mode for updating "

cmd="service apache2 stop"; $cmd || __msgErreurBox "$cmd" $?

echo
echoc v " apache2 service is stoped for updating "

echo

# backup
echo
echoc v "                                  "
echoc v "   Make own backup for updating   "
echoc v "                                  "
echo
__backupDir
# fichiers owncloud/config, data
cmd="rsync -Aax $ocpath/config $ocpath/.htaccess /$__backupDir/"; $cmd || __msgErreurBox "$cmd" $?

# data
if [[ $dataBkupOk =~ [yY] ]]; then
  cmd="rsync -Aax $ocDataDir $ocDataDirRoot/.htaccess $__backupDir/data"; $cmd || __msgErreurBox "$cmd" $?
fi

# BACKUP DE LA BdD
# use debian script user
userBdD=$(cat "/etc/mysql/debian.cnf" | grep -m 1 user | awk -F"= " '{ print $2 }') || \
    __msgErreurBox "userBdD=$(cat \"/etc/mysql/debian.cnf\" | grep -m 1 user | awk -F\"= \" '{ print $2 }')" $?
pwBdD=$(cat "/etc/mysql/debian.cnf" | grep -m 1 password | awk -F"= " '{ print $2 }') || \
    __msgErreurBox "pwBdD=$(cat \"/etc/mysql/debian.cnf\" | grep -m 1 password | awk -F\"= \" '{ print $2 }')" $?
nameTableFile="/$__backupDir/ocdbBackup_$(date +"%Y%m%d").bak"
if [[ -z $pwBdD ]]; then
  mysqldump --opt -u $userBdD $ocDbName > $nameTableFile || __msgErreurBox "mysqldump --opt -u $userBdD $ocDbName > $nameTableFile" $?
else
  mysqldump --opt -u $userBdD --password=$pwBdD $ocDbName > $nameTableFile || __msgErreurBox "mysqldump --opt -u $userBdD --password=$pwBdD $ocDbName > $nameTableFile" $?
fi

echoc v "                                      "
echoc v "   Own backup for Updating Complete   "
echoc v "                                      "
echo

# Sets permissions of the owncloud instance for updating
cmd="chown -R ${htuser}:${htgroup} ${ocpath}"; $cmd || __msgErreurBox "$cmd" $?

echoc v " Sets permissions of the owncloud instance for updating "
echo


# # maintenant utilisons l'app updater ...
echoc v " clean the cache "
sudo -u www-data php $ocpath/updater/application.php upgrade:cleanCache

wget https://download.owncloud.org/community/owncloud-$ocNewVersion.tar.bz2  # old owncloud-10.0.2 new owncloud-10.0.3
wget https://download.owncloud.org/community/owncloud-$ocNewVersion.tar.bz2.md5
md5sum -c owncloud-$ocNewVersion.tar.bz2.md5 < owncloud-$ocNewVersion.tar.bz2 || __msgErreurBox "md5sum -c owncloud-$ocNewVersion.tar.bz2.md5 < owncloud-$ocNewVersion.tar.bz2" $?

wget https://owncloud.org/owncloud.asc
wget https://download.owncloud.org/community/owncloud-$ocNewVersion.tar.bz2.asc
gpg --import owncloud.asc &>/dev/null
gpg --verify owncloud-$ocNewVersion.tar.bz2.asc || __msgErreurBox "gpg --verify owncloud-$ocNewVersion.tar.bz2.asc" $?
if [[ $? -eq 0 ]]; then
  echoc v " owncloud download is ok "
  echo
fi
cmd="tar -xjf owncloud-$ocNewVersion.tar.bz2"; $cmd || __msgErreurBox "$cmd" $?
cmd="mv $ocpath ${ocpath}.old"; $cmd || __msgErreurBox "$cmd" $?
cmd="mv owncloud $ocpath"; $cmd || __msgErreurBox "$cmd" $?
cmd="cp ${ocpath}.old/config/config.php $ocpath/config/config.php"; $cmd || __msgErreurBox "$cmd" $?

cd ${ocpath}.old/apps
for application in *; do
  if [[ ! -e $ocpath/apps/$application ]]; then
    cmd="cp -r ${ocpath}.old/apps/$application $ocpath/apps/$application"; $cmd || __msgErreurBox "$cmd" $?
    if [[ $? -eq 0 ]]; then echo "Copy $application in new owncloud"; fi
  fi
done
cd $REPLANCE

# $ocpath/.htaccess /$ocBackup/"   php_value upload_max_filesize xxxM|G
fileSize=$(cat ${ocpath}.old/.htaccess | grep -m 1 "php_value upload_max_filesize" | awk -F " " '{ print $3 }')
if [[ $fileSize != "513M" ]]; then
  sed -i -e 's/php_value upload_max_filesize 513M/php_value upload_max_filesize '$fileSize'/' \
  -e 's/php_value post_max_size 513M/php_value post_max_size '$fileSize'/' $ocpath/.htaccess
fi

cmd="service apache2 start"; $cmd || __msgErreurBox "$cmd" $?
if [[ $? -eq 0 ]]; then
  echoc v " apache2 service is start "
  echo
fi

cmd="chown -R ${htuser}:${htgroup} ${ocpath}"; $cmd || __msgErreurBox "$cmd" $?
sudo -u $htuser php $ocpath/occ maintenance:mode --off
echoc v " Turned off maintenance mode "
echo

cmd="sudo -u $htuser php $ocpath/occ upgrade"; $cmd || __msgErreurBox "$cmd" $?
if [[ $? -eq 0 ]]; then
  echoc v "                   "
  echoc v "   Upgrade is ok   "
  echoc v "                   "
fi
################################################################################
## modif des droits cf https://doc.owncloud.org/server/latest/admin_manual/installation/installation_wizard.html#post-installation-steps-label

mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater

find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
if [[ ${ocDataDir} != "/var/www/owncloud/data" ]]; then
  find ${ocDataDir}/ -type f -print0 | xargs -0 chmod 0640
  find ${ocDataDir}/ -type d -print0 | xargs -0 chmod 0750
  chmod 750 ${ocDataDirRoot}
  chown ${rootuser}:${htgroup} ${ocDataDirRoot}
  chown -R ${htuser}:${htgroup} ${ocDataDir}
fi

chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/

chmod +x ${ocpath}/occ

if [ -f ${ocpath}/.htaccess ]; then
  chmod 0644 ${ocpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
fi
if [ -f ${ocpath}/data/.htaccess ]; then
  chmod 0644 ${ocpath}/data/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess
fi
if [[ ${ocDataDir} != "/var/www/owncloud/data" ]]; then
  chown ${rootuser}:${htgroup} ${ocDataDirRoot}/.htaccess
  chown ${rootuser}:${htgroup} ${ocDataDir}/.htaccess
  chmod 644 ${ocDataDirRoot}/.htaccess
  chmod 644 ${ocDataDir}/.htaccess
fi
rm $REPLANCE/owncloud*.*
rm -r $REPLANCE/owncloud


echoc v " Permissions and owners modified "
echo

cmd="service apache2 start"; $cmd || __msgErreurBox "$cmd" $?
if [[ $? -eq 0 ]]; then
  echoc v " apache2 service is start "
  echo
fi
cmd="sudo -u $htuser php $ocpath/occ maintenance:mode --off"; $cmd || __msgErreurBox "$cmd" $?
if [[ $? -eq 0 ]]; then
  echoc v " Turned off maintenance mode "
  echo
fi
cmd="sudo -u $htuser php $ocpath/occ files:scan --all"; $cmd || __msgErreurBox "$cmd" $?
if [[ $? -eq 0 ]]; then
  echoc v " Scan the data files "
  echo
fi
ocVer=$(sudo -u $htuser $ocpath/occ -V)
sleep 3
