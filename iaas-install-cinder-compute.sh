##!/bin/bash
########安装
yum -y install openstack-cinder scsi-target-utils openstack-utils

CINDER_DISK=sdb3

##############划分LVM
pvcreate /dev/$CINDER_DISK
vgcreate cinder-volumes  /dev/$CINDER_DISK


################修改keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_host controller
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password 000000


openstack-config --set /etc/cinder/cinder.conf DEFAULT iscsi_helper tgtadm



######配置消息代理
openstack-config --set /etc/cinder/cinder.conf  DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid
openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_hostname controller


######创建数据库连接
openstack-config --set /etc/cinder/cinder.conf database connection  mysql://cinder:000000@controller/cinder

openstack-config --set /etc/cinder/cinder.conf  DEFAULT glance_host controller

###########配置ISCSI目标服务
echo "include /etc/cinder/volumes/*" >>/etc/tgt/targets.conf

##########重启服务
service openstack-cinder-volume restart
service tgtd restart
chkconfig openstack-cinder-volume on
chkconfig tgtd on

