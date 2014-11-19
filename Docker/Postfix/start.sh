#!/bin/bash

postconf -e \
   myhostname=post-office.htmlgraphic.com \
   mydomain=htmlgraphic.com \
   myorigin=\$mydomain \
   mydestination="localhost.localdomain localhost" \
   mynetworks="10.132.0.0/16 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" \
   mail_spool_directory="/var/spool/mail/" \
   smtp_sasl_auth_enable=yes \
   smtp_sasl_password_maps=static:$USER:$PASS \
   smtp_sasl_security_options=noanonymous \
   smtp_tls_security_level=encrypt \
   header_size_limit=4096000 \
   relayhost=[smtp.sendgrid.net]:587


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