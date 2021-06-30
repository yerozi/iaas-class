#!/bin/bash
yum install -y  openstack-nova-compute openstack-utils openstack-selinux

openstack-config --set /etc/nova/nova.conf database connection mysql://nova:000000@controller/nova
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host controller
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password 000000
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/nova/nova.conf DEFAULT qpid_hostname controller
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip 192.168.100.20
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_enabled True
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address 192.168.100.20
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://192.168.100.10:6080/vnc_auto.html
sed -i "/INPUT.*REJECT/i\-A INPUT -m state --state NEW -m tcp -p tcp --dport 5900:5909 -j ACCEPT" /etc/sysconfig/iptables
service iptables reload
openstack-config --set /etc/nova/nova.conf DEFAULT glance_host controller
chkconfig libvirtd on 
chkconfig messagebus on 
chkconfig openstack-nova-compute on
service libvirtd restart
service messagebus restart
service openstack-nova-compute restart
