#!/bin/bash
/usr/sbin/postfix -c /etc/postfix start
tail -f /var/log/mail.log