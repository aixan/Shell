#!/bin/bash
#通过位置变量创建删除Linux系统账户及密码
#$1是执行脚本的第一个参数，$2是执行脚本的第二个参数
useradd "$1"
echo "$2" | passwd --stdin "$1"
#Ubuntu不支持需要用chpasswd
#echo $1:$2 | chpasswd
