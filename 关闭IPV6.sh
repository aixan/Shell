echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf 
echo "NETWORKING_IPV6=no" >>/etc/sysconfig/network
sed -i "s/IPV6INIT=yes/IPV6INIT=no/g" /etc/sysconfig/network-scripts/ifcfg-ens192
sysctl -p
reboot