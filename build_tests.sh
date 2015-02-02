#!/usr/bin/env bash

curl -L "https://shunit2.googlecode.com/files/shunit2-2.1.6.tgz" | tar zx

    #### Extra breathing room
    echo -e '\n'

testPostfixUsername()
{
    echo 'Testing Postfix username.'
    test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep 'p08tf1X' | wc -l)
    assertEquals $test 1
    echo -e '\n'
}


testPostfixPassword()
{
    echo 'Testing Postfix password.'
    test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep 'p@ssw0Rd' | wc -l)
    assertEquals $test 1
    echo -e '\n'
}


testPostfixRelay()
{
    echo 'Relay through SendGrid.'
    test=$(/usr/sbin/postconf relayhost | grep 'htmlgraphic' | wc -l)
    assertEquals $test 1
    echo -e '\n'
}



. shunit2-2.1.6/src/shunit2