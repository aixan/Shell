#!/bin/bash

cat >> /etc/bashrc << "EOF"
HISTTIMEFORMAT="%F %T "
if [ ! -d  /var/log/history ]
then
mkdir -p /var/log/history/
chmod 777 /var/log/history/
chmod +t /var/log/history/
fi

if [ ! -d  /var/log/history/${LOGNAME} ]
then
mkdir -p /var/log/history/${LOGNAME}
chmod 300 /var/log/history/${LOGNAME}
fi
 
export HISTORY_FILE="/var/log/history/${LOGNAME}/history.log" 
export PROMPT_COMMAND='{ date "+%Y-%m-%d %T ##### $(who am i |awk "{print \$1\" \"\$2\" \"\$5}") ##### $(history 1 | { read x cmd; echo "$cmd"; })"; } >> $HISTORY_FILE'
EOF
source /etc/profile
