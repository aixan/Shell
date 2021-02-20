#!/bin/bash
############################################################
# 脚本描述  自动ssh免密登录
# 输入参数说明
# 参数1：
# 参数2：
# 作者          日期            版本
# AIXAN      2020-01-06         v1.0
# 修改时间：                            修改者：
# 修改内容：                            修改描述：
############################################################
[[ -f /usr/bin/expect ]] || { echo "install expect";yum install expect -y; } #若没expect则安装
[ $? = 0 ] || { echo "expect安装失败";exit; } #安装失败则退出
PUB=/'`whoami`'/.ssh/id_dsa.pub #公钥路径
[[ -f $PUB ]] || key_generate #若没公钥则生成
#PWD登录密码
PWD=Az32729842+-
ips=$(cat /etc/hosts | grep -v "::" | grep -v "127.0.0.1")
key_generate () {
    expect -c "set timeout -1;
        spawn ssh-keygen -t rsa;
        expect {
            {Enter file in which to save the key*} {send -- \r;exp_continue}
            {Enter passphrase*} {send -- \r;exp_continue}
            {Enter same passphrase again:} {send -- \r;exp_continue}
            {Overwrite (y/n)*} {send -- n\r;exp_continue}
            eof             {exit 0;}
    };"
}
auto_ssh_copy_id () {
    expect -c "set timeout -1;
        spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub root@$1;
            expect {
                {Are you sure you want to continue connecting *} {send -- yes\r;exp_continue;}
                {*password:} {send -- $2\r;exp_continue;}
                eof {exit 0;}
            };"
}
for ip in $ips
do
    auto_ssh_copy_id $ip  $PWD
done
