#!/bin/bash
#######安装cinder

yum  -y install openstack-cinder

######mysql 配置部分
openstack-config --set /etc/cinder/cinder.conf  database connection  mysql://cinder:000000@controller/cinder

mysql -uroot -p000000 -e"CREATE DATABASE cinder;"
mysql -uroot -p000000 -e"GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost'  IDENTIFIED BY  '000000';"
mysql -uroot -p000000 -e"GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%'  IDENTIFIED BY  '000000';"


su -s /bin/sh -c "cinder-manage db sync" cinder

###########keystone 部分

source /etc/keystone/adminrc.sh
keystone user-create --name=cinder --pass=000000 --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

############创建v1
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage"

keystone endpoint-create  --service-id=$(keystone service-list | awk '/ volume / {print $2}')  --publicurl=http://controller:8776/v1/%\(tenant_id\)s --internalurl=http://controller:8776/v1/%\(tenant_id\)s --adminurl=http://controller:8776/v1/%\(tenant_id\)s

############创建v2
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage v2"

keystone endpoint-create  --service-id=$(keystone service-list | awk '/ volumev2 / {print $2}')  --publicurl=http://controller:8776/v2/%\(tenant_id\)s --internalurl=http://controller:8776/v2/%\(tenant_id\)s --adminurl=http://controller:8776/v2/%\(tenant_id\)s

#############配置文件
openstack-config --set /etc/cinder/cinder.conf DEFAULT  auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri  http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_host controller 
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_protocol http 
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_port 35357 
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder 
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name  service 
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password 000000


openstack-config --set /etc/cinder/cinder.conf  DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid
openstack-config --set /etc/cinder/cinder.conf  DEFAULT qpid_hostname controller


openstack-config --set /etc/cinder/cinder.conf DEFAULT iscsi_helper tgtadm
openstack-config --set /usr/share/cinder/cinder-dist.conf DEFAULT iscsi_helper tgtadm


#############启动服务
service openstack-cinder-api restart
service openstack-cinder-scheduler restart
chkconfig openstack-cinder-api on
chkconfig openstack-cinder-scheduler on


