#!/bin/bash

logFile="/var/log/owncloud.log"
echo "------Scan Audioplayer HiwsT "$(date "+du %d/%m/%y-%H:%M:%S")"----------" >> $logFile
sudo -u www-data php /var/www/owncloud/occ files:scan --all 2>&1 >> $logFile
sudo -u www-data php /var/www/owncloud/occ audioplayer:scan --all 2>&1 >> $logFile
echo " ${1} ${2}" >> $logFile
echo "-----------------------------------------------------------" >> $logFile
