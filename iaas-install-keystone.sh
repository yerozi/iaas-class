#!/bin/bash
yum install -y openstack-keystone python-keystoneclient openstack-utils openstack-selinux
yum -y upgrade
mysql -uroot -p000000 -e "create database IF NOT EXISTS keystone;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '000000' ;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '000000' ;"
openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:000000@controller/keystone
su -s /bin/sh -c "keystone-manage db_sync" keystone
ADMIN_TOKEN=$(openssl rand -hex 10)
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /etc/keystone/* /var/log/keystone/*
chmod -R o-rwx /etc/keystone/ssl
chkconfig openstack-keystone on
service openstack-keystone start
touch /var/log/keystone/keystone-tokenflush.log
chmod 777 /var/log/keystone/keystone-tokenflush.log
(crontab -l -u keystone 2>/var/log/keystone/keystone-tokenflush.log | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone
export OS_SERVICE_TOKEN=$ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0
keystone user-create --name=admin --pass=000000 
keystone role-create --name=admin
keystone tenant-create --name=admin --description="Admin Tenant"
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin
keystone user-create --name=demo --pass=000000
keystone tenant-create --name=demo --description="Demo Tenant"
keystone user-role-add --user=demo --role=_member_ --tenant=demo
keystone tenant-create --name=service --description="Service Tenant"
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ identity / {print $2}') --publicurl=http://controller:5000/v2.0 --internalurl=http://controller:5000/v2.0 --adminurl=http://controller:35357/v2.0
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
cat > /etc/keystone/admin-openrc.sh <<-EOF
export OS_USERNAME=admin
export OS_PASSWORD=000000
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://controller:35357/v2.0
EOF
cat > /etc/keystone/demo-openrc.sh <<-EOF
export OS_USERNAME=demo
export OS_PASSWORD=000000
export OS_TENANT_NAME=demo
export OS_AUTH_URL=http://controller:35357/v2.0
EOF

