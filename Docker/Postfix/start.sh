#!/bin/bash

# These are required when postfix runs chrooted
#
[[ -z $(ls /var/spool/postfix/etc) ]] && {
    for n in hosts localtime nsswitch.conf resolv.conf services
    do 
        cp /etc/$n /var/spool/postfix/etc
    done
}

# These also need setgid to stop 'postfix check' worrying.
#
[[ -z $(find /usr/sbin/ -name postqueue -o -name postdrop -perm -2555) ]] && \
    chmod g+s /usr/sbin/post{drop,queue}

# Spin everything up
#
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf