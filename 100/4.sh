#!/bin/bash
#一键部署LAMP（RPM包版本）
#使用yum安装部署LNMP，需要提前配置好YUM源，否则该脚本会失效
yum -y install httpd
yum -y install mariadb mariadb-devel mariadb-server
yum -y install php php-mysql

#启动服务并设置开机自启动
systemctl start httpd mariadb
systemctl enable httpd mariadb
