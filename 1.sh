#!/bin/bash
############################################################
# 脚本描述  系统初始化
# 输入参数说明
# 参数1：
# 参数2：
# 作者		日期		版本
# AIXAN      2020-01-06         v1.0
# 修改时间：				修改者：
# 修改内容：				修改描述：
############################################################
#检测是否为root用户
if [ $UID -ne 0 ];then
        echo "Must be root can do this."
        exit 9
fi

#检测网络
echo "检测网络中......"
/bin/ping www.baidu.com -c 2 &>/dev/null
if [ $? -ne 0 ];then
        echo "现在网络无法通信，准备设置网络"
        read -p 'pls enter your ip: ' IP
        read -p 'pls enter your gateway: ' GW 
        read -p 'pls enter your netmask: ' NM 
        read -p 'pls enter your netcard: ' NC
        echo "IPADDR=$IP" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "NETMASK=$NM" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "GATEWAY=$GW" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "DNS1=114.114.114.114" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "DNS2=8.8.8.8" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-$NC
        sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-$NC
        /etc/init.d/network restart
        echo -e "\033[031m network is configure ok.\033[0m"
else
        echo -e "\033[031m network is ok.\033[0m"
fi

#关闭 ctrl + alt + del
echo "关闭 ctrl + alt + del ......."
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab
sed -i 's/^id:5:initdefault:/id:3:initdefault:/' /etc/inittab

#关闭ipv6
echo "关闭IPv6....."
echo "alias net-pf-10 off" >> /etc/modprobe.conf
echo "alias ipv6 off" >> /etc/modprobe.conf
/sbin/chkconfig --level 35 ip6tables off
echo -e "\033[031m ipv6 is disabled.\033[0m"

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭NetworkManager网络管理
systemctl stop NetworkManager
systemctl disable NetworkManager

#关闭selinux
echo "关闭SElinux......"
sed -i '/SELINUX/s/enforcing$/disabled/' /etc/selinux/config
echo -e "\033[31m selinux is disabled,if you need,you must reboot.\033[0m"
sleep 10s

#更新yum源
echo "备份yum源......"
yum -y install wget
mkdir /etc/yum.repos.d/backup && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
sys_ver=`cat /etc/redhat-release |awk '{print $4}' | awk -F '.' '{print $1}'`
if [ $sys_ver -eq 6 ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
        wget -O /etc/yum.repos.d/epel-6.repo http://mirrors.aliyun.com/repo/epel-6.repo
	yum clean all
        yum makecache
elif [ $sys_ver -eq 7 ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
        wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all
        yum makecache
elif [ $sys_ver -eq 5 ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo
        wget -O /etc/yum.repos.d/epel-5.repo http://mirrors.aliyun.com/repo/epel-5.repo
	yum clean all
        yum makecache
fi

#安装基础库
echo "安装基础软件包......"
yum -y install screen yum-utils vim ntp net-tools epel-release openssh openssh-clients openssh-server lrzsz tree
#yum install gcc -y kernel-headers kernel-devel

#设置时钟同步
echo "设置时钟同步......"
ntpdate ntp.aliyun.com
echo "*/5 * * * * /usr/sbin/ntpdate ntp.aliyun.com >> /var/log/ntp.log 2>&1;/sbin/hwclock -w" >> /var/spool/cron/root

#创建用户提权
#useradd aix
#echo "32729842" |passwd --stdin aix &> /dev/null
#sed -i '/^## Allow root to run any commands anywhere/a\aix     ALL=(ALL)       ALL'  /etc/sudoers
#visudo -c

#修改文件打开数
echo "修改文件打开数......"
cat >> /etc/security/limits.conf <<EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
echo "ulimit -SH 65535" >> /etc/rc.local

#优化内核参数
echo "优化内核参数....."
cat >> /etc/sysctl.conf << ENDF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog =  32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024  65535
vm.swappiness=15
ENDF
sysctl -p

#zabbix-agent安装
#read -p 'pls enter your hostname: ' HN
#rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
#yum -y install zabbix-agent
#sed -i "s/^Hostname=.*/Hostname=$HN/" /etc/zabbix/zabbix_agentd.conf
#sed -i "s/^Server=.*/Server=192.168.10.5/" /etc/zabbix/zabbix_agentd.conf
#sed -i "s/^ServerActive=.*/ServerActive=192.168.10.5/" /etc/zabbix/zabbix_agentd.conf
#sed -i "s/# UnsafeUserParameters=0/UnsafeUserParameters=1/" /etc/zabbix/zabbix_agentd.conf
#systemctl enable zabbix-agent &> /dev/null
#systemctl start zabbix-agent &> /dev/null || echo -e "\033[031m ZABBIX is disabled.\033[0m"

#主机信息添加到hosts文件
#echo "192.168.10.11 AIX11" >> /etc/hosts
#echo "192.168.10.12 AIX12" >> /etc/hosts

#优化ssh参数
#sed -i 's/^#Port 22/Port 47831/' /etc/ssh/sshd_config #修改默认SSH端口
#sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config  #禁止root 用户登录
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config  #禁止空密码登录
sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config  #关闭SSH反向查询，提高SSH访问速度
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" /etc/ssh/sshd_config
#sed -i 's/#   Port 22/Port 47831/' /etc/ssh/ssh_config   #修改SSH连接端口
echo "Warning, All your actions will be recorded,please be careful."  >> /etc/motd #配置 ssh 登入提示语
/etc/init.d/sshd restart

#更新系统
yum -y update

#重启
reboot
