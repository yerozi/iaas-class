#!/bin/bash
yum install -y openstack-glance python-glanceclient wget perl
perl -p -i -e "s/^(if _fastmath is not None .*:)/#\1/" /usr/lib64/python2.6/site-packages/Crypto/Util/number.py
perl -p -i -e "s/^(\s*_warn.*Not using mpz_powm_sec.*)/#\1/" /usr/lib64/python2.6/site-packages/Crypto/Util/number.py
mysql -uroot -p000000 -e "create database IF NOT EXISTS glance ;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '000000' ;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '000000' ;"
openstack-config --set /etc/glance/glance-api.conf database connection mysql://glance:000000@controller/glance
openstack-config --set /etc/glance/glance-registry.conf database connection mysql://glance:000000@controller/glance
su -s /bin/sh -c "glance-manage db_sync" glance
source /etc/keystone/admin-openrc.sh
keystone user-create --name=glance --pass=000000
keystone user-role-add --user=glance --tenant=service --role=admin
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_host controller
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_password 000000
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_host controller
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_password 000000
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone
keystone service-create --name=glance --type=image --description="OpenStack Image Service"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}') --publicurl=http://controller:9292 --internalurl=http://controller:9292 --adminurl=http://controller:9292
chkconfig openstack-glance-api on
chkconfig openstack-glance-registry on
service openstack-glance-api restart
service  openstack-glance-registry restart


