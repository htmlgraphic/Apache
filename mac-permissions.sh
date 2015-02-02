# These file and folder permissions are manually executed to match
# the linked data directly to the local OS X file system.

# Group perimission tweak for local development
groupdel staff
groupmod -g 50 www-data
usermod -s /bin/false -u 1000 nobody

# Apache should be able to write to the /tmp directory
chown nobody:www-data /tmp