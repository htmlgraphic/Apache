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
	test=$(/usr/bin/wget -qO- --no-check-certificate https://127.0.0.1 | grep -w "Hello World\\!" | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testCLI_max_execution_time()
{
	max_execution_time=$(php -i | grep 'max_execution_time')
	echo 'Test max_execution_time, currently set to "'$max_execution_time'"'
	test=$(echo $max_execution_time | grep 'max_execution_time => 0 => 0' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testCLI_MemoryLimit()
{
	memory_limit=$(php -i | grep 'memory_limit')
	echo 'Test memory_limit, currently set to "'$memory_limit'"'
	test=$(echo $memory_limit | grep 'memory_limit => -1 => -1' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testCLI_upload_max_filesize()
{
	upload_max_filesize=$(php -i | grep 'upload_max_filesize')
	echo 'Test upload_max_filesize, currently set to "'$upload_max_filesize'"'
	test=$(echo $upload_max_filesize | grep 'upload_max_filesize => 1000M => 1000M' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testCLI_post_max_size()
{
	post_max_size=$(php -i | grep 'post_max_size')
	echo 'Test post_max_size, currently set to "'$post_max_size'"'
	test=$(echo $post_max_size | grep 'post_max_size => 1000M => 1000M' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testCLI_max_input_time()
{
	max_input_time=$(php -i | grep 'max_input_time')
	echo 'Test max_input_time, currently set to "'$max_input_time'"'
	test=$(echo $max_input_time | grep 'max_input_time => -1 => -1' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testApache_max_execution_time()
{
	max_execution_time=$(cat /etc/php/7.3/apache2/php.ini | grep 'max_execution_time')
	echo 'Test max_execution_time, currently set to "'$max_execution_time'"'
	test=$(echo $max_execution_time | grep 'max_execution_time = 300' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testApache_MemoryLimit()
{
	memory_limit=$(cat /etc/php/7.3/apache2/php.ini | grep 'memory_limit')
	echo 'Test memory_limit, currently set to "'$memory_limit'"'
	test=$(echo $memory_limit | grep 'memory_limit = -1' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testApache_upload_max_filesize()
{
	upload_max_filesize=$(cat /etc/php/7.3/apache2/php.ini | grep 'upload_max_filesize')
	echo 'Test upload_max_filesize, currently set to "'$upload_max_filesize'"'
	test=$(echo $upload_max_filesize | grep 'upload_max_filesize = 1000M' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testApache_post_max_size()
{
	post_max_size=$(cat /etc/php/7.3/apache2/php.ini | grep 'post_max_size')
	echo 'Test post_max_size, currently set to "'$post_max_size'"'
	test=$(echo $post_max_size | grep 'post_max_size = 1000M' | wc -l)
	assertEquals 1 $test
	echo -e '\n'
}

testApache_max_input_time()
{
	max_input_time=$(cat /etc/php/7.3/apache2/php.ini | grep 'max_input_time')
	echo 'Test max_input_time, currently set to "'$max_input_time'"'
	test=$(echo $max_input_time | grep 'max_input_time = 300' | wc -l)
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

. /opt/tests/shunit2-2.1.7/shunit2
