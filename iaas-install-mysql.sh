#!/bin/bash
yum install -y mysql mysql-server MySQL-python expect
sed -i  "/^symbolic-links/a\bind-address=192.168.100.10\ndefault-storage-engine = innodb\ninnodb_file_per_table\ncollation-server = utf8_general_ci\ninit-connect = 'SET NAMES utf8'\ncharacter-set-server = utf8" /etc/my.cnf
service mysqld start
chkconfig mysqld on
expect -c "
spawn /usr/bin/mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Set root password?\"
send \"y\r\"
expect \"New password:\"
send \"000000\r\"
expect \"Re-enter new password:\"
send \"000000\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"n\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
"
