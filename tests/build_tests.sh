#!/usr/bin/env bash
. /etc/environment

#### Extra breathing room
echo -e '\n'

testPostfixUsername()
{
	test=0
	echo 'Testing Postfix username, currently set to "'${SASL_USER}'"'
	if [ ! -z "${SASL_USER}" ]; then
		test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep "${SASL_USER}" | wc -l)
	else
		echo 'ENV $SASL_USER is not set';
	fi
	assertEquals 1 $test
	echo -e '\n'
}


testPostfixPassword()
{
	echo 'Testing Postfix password, currently set to "'${SASL_PASS}'"'
	if [ ! -z "${SASL_PASS}" ]; then
		test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep "${SASL_PASS}" | wc -l)
	else
		echo 'ENV $SASL_PASS is not set';
	fi
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


testNODE_MemoryLimit()
{
	memory_limit=$(php -i | grep 'memory_limit')
	echo 'Test memory_limit, currently set to "'$memory_limit'"'
	test=$(echo $memory_limit | grep 'memory_limit => -1 => -1' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}


testNODE_ENVIRONMENT()
{
	echo 'Test env NODE_ENVIRONMENT, currently set to "'${NODE_ENVIRONMENT}'"'
	node_env=0;

	# Depending on the type of environment dev or production an
	# environment variable should be set
	if [[ ${NODE_ENVIRONMENT} == 'dev' ]] || [[ ${NODE_ENVIRONMENT} == 'production' ]]; then
		node_env=1;
	fi
	assertEquals 1 $node_env
	echo -e '\n'
}


testNODE_ENVIRONMENT_PHP()
{
	echo 'Test env NODE_ENVIRONMENT within Apache'
	node_env=0;

	dev=$(/usr/bin/wget -q -O- http://127.0.0.1 | grep -w "NODE_ENVIRONMENT=dev" | wc -l);
	prod=$(/usr/bin/wget -q -O- http://127.0.0.1 | grep -w "NODE_ENVIRONMENT=production" | wc -l)

	# Depending on the type of environment dev or production an
	# environment variable should be set
	if [[ $dev == 1 ]] || [[ $prod == 1 ]]; then
		node_env=1;
	fi
	assertEquals 1 $node_env
	echo -e '\n'
}

. /opt/tests/shunit2-2.1.6/src/shunit2
