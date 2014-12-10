#!/bin/bash

if [ ! -f /var/lib/mysql/ibdata1 ]; then

    mysql_install_db

    /usr/bin/mysqld_safe &
    mysqladmin --silent --wait=30 ping || exit 1

    echo "GRANT ALL PRIVILEGES ON *.* TO admin@'%' IDENTIFIED BY 'CHANGE_ME' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

    killall mysqld
    sleep 10s
fi

mysqld_safe