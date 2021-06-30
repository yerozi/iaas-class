#!/bin/bash
yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient
openstack-config --set /etc/nova/nova.conf database connection mysql://nova:000000@controller/nova
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/nova/nova.conf DEFAULT qpid_hostname controller
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip 192.168.100.10
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 192.168.100.10
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address 192.168.100.10
sed -i "/INPUT.*REJECT/i\-A INPUT -m state --state NEW -m tcp -p tcp --dport 5900:5909 -j ACCEPT" /etc/sysconfig/iptables
service iptables reload
mysql -uroot -p000000 -e "create database IF NOT EXISTS nova;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '000000' ;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '000000' ;"
su -s /bin/sh -c "nova-manage db sync" nova
source /etc/keystone/admin-openrc.sh
keystone user-create --name=nova --pass=000000
keystone user-role-add --user=nova --tenant=service --role=admin
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host controller
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password 000000
keystone service-create --name=nova --type=compute --description="OpenStack Compute"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ compute / {print $2}') --publicurl=http://controller:8774/v2/%\(tenant_id\)s --internalurl=http://controller:8774/v2/%\(tenant_id\)s --adminurl=http://controller:8774/v2/%\(tenant_id\)s
chkconfig openstack-nova-api on
chkconfig openstack-nova-cert on
chkconfig openstack-nova-consoleauth on
chkconfig openstack-nova-scheduler on
chkconfig openstack-nova-conductor on
chkconfig openstack-nova-novncproxy on
service openstack-nova-api restart
service openstack-nova-cert restart
service openstack-nova-consoleauth restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart
service openstack-nova-novncproxy restart

