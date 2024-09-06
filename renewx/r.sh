#!/bin/bash

randNumMinStart=$(($RANDOM%59))
randNumMinStop=$(($RANDOM%59))
randNumHourStart=$(($[RANDOM%5]+8))
randNumHourStop_1=$(($[RANDOM%5]+13))

echo -e "*/20 * * * * /sbin/ntpdate -u pool.ntp.org > /dev/null 2>&1
25 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
"$[randNumMinStart] $[randNumHourStart]" * * 1-5 docker start RenewX
"$[randNumMinStop] $[randNumHourStop_1]" * * 1-5 docker stop RenewX" > /var/spool/cron/crontabs/root

sudo chmod 777 /var/spool/cron/crontabs/root
sudo crontab /var/spool/cron/crontabs/root
#sudo systemctl restart cron
