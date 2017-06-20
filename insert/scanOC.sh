#!/bin/bash

logFile="/var/log/owncloud.log"
sudo -u www-data php /var/www/owncloud/occ files:scan ${3}
sleep 1
echo "------Scan Audioplayer HiwsT "$(date "+du %d/%m/%y-%H:%M:%S")"----------" >> $logFile
sudo -u www-data php /var/www/owncloud/occ audioplayer:scan ${3} 2>&1 >> $logFile
echo " ${1} ${2}" >> $logFile
echo "-----------------------------------------------------------" >> $logFile
