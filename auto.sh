#!/bin/bash


#download mysql57.tar.gz
##wget -O /mysql57.tar.gz ftp://192.168.149.161/pub/mysql57.tar.gz


read -p 'please input Mysql-master IP: ' masterip
read -p 'please input Mysql-slave IP: ' slaveip




del_my_cnf(){
# delete the /etc/my.cnf on  aim-host
/usr/bin/expect<<EOF
set timeout 30
spawn ssh -l root $1
expect "password:"
send "123\r"
expect "]#"
send "rm -f /etc/my.cnf\r"
expect "]#"
send "exit\r"
expect "]#"
expect eof
EOF
}



#test_ab(){
##test_mysql_a_ping_mysql_b
#/usr/bin/expect<<EOF
#set timeout 30
#spawn ssh -l root $1
#expect "password:"
#send "123\r"
#expect "]#"
#send {ssh -l root $2}
#send \r
#expect "(yes/no)?"
#send "yes\r"
#expect "password:"
#send "123\r"
#expect "]#"
#send "exit\r"
#send "exit\r"
#EOF
#
#
#}


set_mysql_master_cnf(){
#write configuration file for mysql_master
cat >/etc/my.cnf<<EOF
[mysqld]
socket=/var/lib/mysql/mysql.sock
log-bin=master
log-bin-index=master
server-id=1
[mysql]
socket=/var/lib/mysql/mysql.sock
EOF
}


set_mysql_slave_cnf(){
#set_mysql_slave_cnf
cat >/etc/my.cnf<<EOF
[mysqld]
socket=/var/lib/mysql/mysql.sock
server-id=2
[mysql]
socket=/var/lib/mysql/mysql.sock
EOF

}




init_mysql(){
#initialization mysql
/usr/bin/expect<<EOF
set timeout 80
spawn scp /mysql57.tar.gz $1:/
expect "password:"
send "123\r"
expect eof 

spawn scp /etc/my.cnf $1:/etc/my.cnf
expect "password:"
send "123\r"
expect eof

spawn ssh -l root $1
expect "password:"
send "123\r"
expect "]#"
send "tar -xvf /mysql57.tar.gz -C /usr/local/ \r"
expect "]#"
send "groupadd -g 27 mysql\r"
expect "]#"
send "useradd -M -u 27 -g 27 mysql -s /sbin/nologin \r"
expect "]#"
send "chown -R mysql.mysql /usr/local/mysql \r"
expect "]#"
send "mkdir /var/lib/mysql\r"
expect  "]#"
send "chown mysql.mysql /var/lib/mysql \r"
expect "]#"
send "> /var/log/mysqld.log \r"
expect "]#"
send "/usr/local/mysql/bin/mysqld --initialize --user=mysql --datadir=/usr/local/mysql/data &> /var/log/mysqld.log\r"
expect "]#"
send "exit\r"
expect "]#"
expect eof
EOF
}

start_mysql_server(){
#start mysql server
/usr/bin/expect<<EOF
set timeout 60
spawn ssh -l root $1
expect "password:"
send "123\r"
expect "]#"
send "/usr/local/mysql/support-files/mysql.server start \r"
expect "]#"
send "exit\r"
expect "]#"
expect eof
EOF

}



change_mysql_passwd(){
#
#/usr/bin/expect<<EOF
#set timeout 30
#spawn ssh -l root $1
#expect "password:"
#send "123\r"
#expect "]#"
#send {pas=\`awk '/root@localhost/{print \$NF}' /var/log/mysqld.log\`}
#send "\r"
#expect "]#"
#send {/usr/local/mysql/bin/mysql -u root -p\$pas}
#send \r
#expect "mysql>"
#send "set password='123';\r"
#expect "mysql>"
#send "exit\r"
#expect eof
#EOF
/usr/bin/expect changemysqlpasswd.sh $1
}


grant_mysqlb(){
/usr/bin/expect<<EOF
set timeout 30
spawn ssh -l root $1
expect "password:"
send "123\r"
expect "]#"
send "/usr/local/mysql/bin/mysql -u root -p'123' \r"
expect "mysql>"
send "grant replication slave on *.* to slave@'%' identified by '123';\r"
expect "mysql>"
send "exit\r"
expect "]#"
send "exit\r"
expect "]#"
expect eof
EOF

}


mysqla_master_to_b(){
/usr/bin/expect<<EOF
set timeout 30
spawn ssh -l root $1
expect "password:"
send "123\r"
expect "]#"
send {/usr/local/mysql/bin/mysql -u root -p123 -e "show master status\G" > txt.txt}
send \r
expect "]#"
send "scp /root/txt.txt $2:/root/ \r"
expect "password:"
send "123\r"
expect "]#"
send "exit\r"
EOF
}



config_mysqlb(){
/usr/bin/expect<<EOF
set timeout 30
spawn ssh -l root $1
expect "password:"
send "123\r"
expect "]#"
send {masterfile=\`awk '{if(NR==2){ print \$NF }}' txt.txt\` }
send \r
expect "]#"
send {masterpos=\`awk '{if(NR==3){ print \$NF }}' txt.txt\` }
send \r
expect "]#"
send {echo \$masterfile \$masterpos }
send \r
expect "]#"
send {/usr/local/mysql/bin/mysql -u root -p123 -e "stop slave;"}
send \r
expect "]#"
send {/usr/local/mysql/bin/mysql -u root -p123 -e "change master to master_host='$2',master_user='slave',master_password='123',master_port=3306,master_log_file='\$masterfile',master_log_pos=\$masterpos;"}
send \r
expect "]#"
send {/usr/local/mysql/bin/mysql -u root -p123 -e "start slave;"}
send \r
expect "]#"
send "exit\r"
EOF
}




del_my_cnf $masterip
del_my_cnf $slaveip
#test_ab $masterip $slaveip
set_mysql_master_cnf
init_mysql $masterip
set_mysql_slave_cnf
init_mysql $slaveip
start_mysql_server $masterip
change_mysql_passwd $masterip
grant_mysqlb $masterip
start_mysql_server $slaveip
change_mysql_passwd $slaveip
mysqla_master_to_b $masterip $slaveip
config_mysqlb $slaveip  $masterip 
sleep 2
echo "*************************************"
echo "*************************************"
echo "*************************************"
echo "*************************************"
echo "**********O(∩_∩)O******************"
echo "*************************************"
echo "*************************************"
echo "*************************************"
echo "*************************************"
echo "*************************************"
echo "*************执行成功！**************"
echo "*************************************"
echo "*************************************"
