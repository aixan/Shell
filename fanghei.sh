#!/bin/bash
############################################################
# 脚本描述 SSH防黑破解 
# 作者          日期            版本
# AIXAN      2020-01-06         v1.0
############################################################

# 检测是否为root用户
if [ $UID -ne 0 ];then
        echo "Must be root can do this."
        exit 9
fi
# 创建文件夹
[ ! -d /data/tools ] && mkdir -p /data/tools
[ ! -d /data/logs ] && mkdir -p /data/logs

# 创建防黑脚本
cat > /data/tools/fanghei.sh <<"EOF"
#!/bin/bash
cat /var/log/secure|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}' > /data/logs/black.log
DEFINE="5"
for i in `cat /data/logs/black.log`
do
IP=`echo $i |awk -F= '{print $1}'`
NUM=`echo $i|awk -F= '{print $2}'`
if [ $NUM -gt $DEFINE ]; then
grep $IP /etc/hosts.deny >/dev/null
if [ $? -gt 0 ];then
echo "sshd:$IP" >> /etc/hosts.deny
fi
fi
done
EOF
# 添加执行权限
chmod +x /data/tools/fanghei.sh
# 添加守护进程
cat >>/var/spool/cron/root<<EOF
* * * * * /bin/bash /data/tools/fanghei.sh >/dev/null 2>&1    #每分钟检测一次
EOF
# 查看守护进程
crontab -u root -l
# 删除脚本
rm -rf fanghei.sh