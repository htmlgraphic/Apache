# Process user for local development

# Postfix uses testing system and holds email(s) from being released into the wild
postconf -e \
   myhostname=dev-build.htmlgraphic.com \
   mydomain=htmlgraphic.com \
   mydestination="localhost.localdomain localhost" \
   mail_spool_directory="/var/spool/mail/" \
   virtual_alias_maps=hash:/etc/postfix/virtual \
   smtp_sasl_auth_enable=yes \
   smtp_sasl_password_maps=static:testing:tdesigns1 \
   smtp_sasl_security_options=noanonymous \
   smtp_tls_security_level=encrypt \
   header_size_limit=4096000 \
   relayhost=[email-test.htmlgraphic.com]:2525

touch /etc/postfix/virtual
postmap /etc/postfix/virtual

/etc/init.d/postfix reload