#!/usr/bin/env bash

curl -L "https://github.com/aetheric/shunit2/archive/2.1.6.tar.gz" | tar zx

	#### Extra breathing room
	echo -e '\n'

testPostfixUsername()
{
	echo 'Testing Postfix username'
	test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep 'p08tf1X' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}


testPostfixPassword()
{
	echo 'Testing Postfix password'
	test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep 'p@ssw0Rd' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}


testPostfixRelay()
{
	echo 'Relay through SendGrid'
	test=$(/usr/sbin/postconf relayhost | grep 'htmlgraphic' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}


testHTTP()
{
	echo 'Test Apache HTTP'
	test=$(/usr/bin/wget -q -O- http://127.0.0.1 | grep -w "Hello World\\!" | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}


testHTTPS()
{
	echo 'Test Apache HTTPS'
	test=$(/usr/bin/wget -q -O- --no-check-certificate https://127.0.0.1 | grep -w "Hello World\\!" | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}


testNODE_ENVIRONMENT()
{
	echo 'Test env NODE_ENVIRONMENT'

	# Depending on the type of environment dev or production should appear
	# on the initial landing page of built container

	dev=$(/usr/bin/wget -q -O- http://127.0.0.1 | grep -w "dev" | wc -l);
	prod=$(/usr/bin/wget -q -O- http://127.0.0.1 | grep -w "production" | wc -l)

	if [ "$dev" == 1 ]; then
		# build is dev
		assertEquals 1 $dev
	else
		# build is dev
		assertEquals 1 $prod
	fi

	echo -e '\n'
}

. shunit2-2.1.6/src/shunit2
