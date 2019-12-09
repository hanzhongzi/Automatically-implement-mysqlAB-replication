#!/usr/bin/expect
set ip [lindex $argv 0]
set timeout 30
spawn ssh -l root $ip
expect "password:"
send "123\r"
expect "]#"
send  "passwd=\`awk 'END{ print \$NF }' /var/log/mysqld.log\`"
send "\r"
expect "]#"
send "/usr/local/mysql/bin/mysql -u root -p\$passwd \r"
expect "mysql>"
send "set password='123';\r"
expect "mysql>"
send "exit\r"
expect eof
