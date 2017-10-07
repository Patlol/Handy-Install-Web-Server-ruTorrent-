#!/usr/bin/env bash

# 0 2 /29 * *
# 6 1,13 * * * certbot renew --renew-hook "service restart apache2"
#

repCertbot=$(which certbot)
if [[ $? -ne 0 ]]; then
  echo -e "\n$(date) ---------------\nIssue to attempt locate cerbot" >> /var/log/letsencrypt/letsencrypt-cron.log 2>&1
  exit 1
fi

echo -e "\n$(date) ---------------" >> /var/log/letsencrypt/letsencrypt-cron.log 2>&1
$repCertbot renew --renew-hook "service apache2 restart || service apache2 status" >> /var/log/letsencrypt/letsencrypt-cron.log 2>&1
