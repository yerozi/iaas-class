#!/bin/bash
yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient openstack-neutron-openvswitch
openstack-config --set /etc/neutron/neutron.conf database connection mysql://neutron:000000@controller/neutron
mysql -uroot -p000000 -e "create database IF NOT EXISTS neutron;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '000000' ;"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '000000' ;"
source /etc/keystone/admin-openrc.sh
keystone user-create --name neutron --pass 000000
keystone user-role-add --user neutron --tenant service --role admin
keystone service-create --name neutron --type network --description "OpenStack Networking"
keystone endpoint-create --service-id $(keystone service-list | awk '/ network / {print $2}') --publicurl http://controller:9696 --adminurl http://controller:9696 --internalurl http://controller:9696
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname controller
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT control_exchange neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host controller
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password 000000
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://controller:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password 000000
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://controller:35357/v2.0
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron
openstack-config --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal False
openstack-config --set /etc/nova/nova.conf DEFAULT vif_plugging_timeout 10
chkconfig openvswitch on
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://controller:8774/v2
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_username nova
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $(keystone tenant-list | awk '/ service / { print $2 }')
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_password 000000
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_auth_url http://controller:35357/v2.0
sed -i -e '/net.ipv4.ip_forward.*/d' -e '/net.ipv4.conf.all.rp_filter.*/d' -e '/net.ipv4.conf.default.rp_filter.*/d' /etc/sysctl.conf
cat >>/etc/sysctl.conf <<-EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF
sysctl -p
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types flat
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks physnet1
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs network_vlan_ranges physnet1
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings physnet1:br-eth1
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent
chkconfig neutron-openvswitch-agent on
chkconfig NetworkManager off
service NetworkManager stop
cat >>/etc/sysconfig/network-scripts/ifcfg-br-eth1 <<-EOF
DEVICE=br-eth1
`cat /etc/sysconfig/network-scripts/ifcfg-eth1 |grep IPADDR`
`cat /etc/sysconfig/network-scripts/ifcfg-eth1 |grep PREFIX`
`cat /etc/sysconfig/network-scripts/ifcfg-eth1 |grep NETMASK`
`cat /etc/sysconfig/network-scripts/ifcfg-eth1 |grep GATEWAY`
`cat /etc/sysconfig/network-scripts/ifcfg-eth1 |grep DNS`
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
DEFROUTE=yes
NAME="System br-eth1"
EOF
cp /etc/sysconfig/network-scripts/ifcfg-eth1 /etc/sysconfig/network-scripts/ifcfg-eth1.bak
sed -i -e '/^UUID.*/d' -e '/^BOOTPROTO/d' -e '/^IPADDR/d' -e '/^PREFIX/d' -e '/^NETMASK/d' -e '/^GATEWAY/d' -e '/^DNS/d' /etc/sysconfig/network-scripts/ifcfg-eth1
#touch /var/log/openvswitch/ovs-ctl.log
service openvswitch restart
ovs-vsctl add-br br-int
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 eth1
ethtool -K eth1 gro off
service network restart
openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy true
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret metadata
service openstack-nova-api restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart
service neutron-openvswitch-agent restart
service neutron-server restart
chkconfig neutron-server on

