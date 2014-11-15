#!/bin/sh
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
echo 10.132.191.193 mysql >> /etc/hosts

# Start rsyslogd for proper logging
sudo service rsyslog start

# Start fail2ban
sudo /etc/init.d/fail2ban start

exit 0