#!/bin/bash
IP="0.0.0.0"
mkdir /backup/{mysql,tools,web,logs}
#创建备份用户
useradd backup
echo backup:PASSWORD | chpasswd
#设置ACL权限
setfacl -R -m user:backup:rwx /backup
#创建WEB备份脚本
cat >/backup/tools/webbackup.sh <<"EOF"
#!/bin/bash
WEB=/home/wwwroot
time=`date +%Y-%m-%d`
WEBBACK=/backup/web
tar -zcPf $WEBBACK/web-"$time".tar.gz $WEB &> /dev/null
if [ $? -eq 0 ];then
    find $WEBBACK -name "tar.gz" -type -f -mtime +15 -exec rm -rf {} \;
    echo "$time ${WEBBACK} BACKUP SUCCEEDED!" >> /backup/logs/webback.log
else
    echo "$time BACKUP FAILURE" >> /backup/logs/webback.log
fi
EOF
#创建MYSQL备份脚本
cat >/backup/tools/mybackup.sh <<"EOF"
#!/bin/bash
time=`date +%Y-%m-%d`
MYBACK=/backup/mysql
mysqldump -h192.168.10.40 -uroot -pPASSWD DATA > $MYBACK/mysql-"$time".sql
if [ $? -eq 0 ];then
    find $MYBBACK -name ".sql" -type -f -mtime +15 -exec rm -rf {} \;
    echo "$time ${MYBBACK} BACKUP SUCCEEDED!" >> /backup/logs/myback.log
else
    echo "$time BACKUP FAILURE" >> /backup/logs/myback.log
fi
EOF
cat >> /var/spool/cron/backup <<EOF
0 2 * * * sh /backup/tools/webbackup.sh
0 3 * * * rsync -avz --delete backup@$IP:/backup/web/ /backup/web/
0 2 * * * /bin/bash /backup/tools/mybackup.sh
0 3 * * * rsync -avz --delete backup@$IP:/backup/mysql/ /backup/mysql/
EOF
