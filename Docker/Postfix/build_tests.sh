#!/usr/bin/env bash

curl -L "https://shunit2.googlecode.com/files/shunit2-2.1.6.tgz" | tar zx

testPostfixUsername()
{
    echo 'Testing Postfix username.'
    test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep 'p08tf1X' | wc -l)
    assertEquals $test 1
}


testPostfixPassword()
{
    echo -e '\n'
    echo 'Testing Postfix password.'
    test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep 'p@ssw0Rd' | wc -l)
    assertEquals $test 1
}


testPostfixRelay()
{
    echo -e '\n'
    echo 'Relay through SendGrid.'
    test=$(/usr/sbin/postconf relayhost | grep 'sendgrid' | wc -l)
    assertEquals $test 1
}


testPostfixMyNetworks1()
{
    echo -e '\n'
    echo 'Allow 54.225.164.191 this network to send email.'
    test=$(/usr/sbin/postconf mynetworks | grep '54.225.164.191' | wc -l)
    assertEquals $test 1
}

testPostfixMyNetworks2()
{
    echo -e '\n'
    echo 'Allow 104.236.0.0/18 this network to send email.'
    test=$(/usr/sbin/postconf mynetworks | grep '104.236.0.0/18' | wc -l)
    assertEquals $test 1
}

testPostfixMyNetworks3()
{
    echo -e '\n'
    echo 'Allow 10.132.0.0/16 this network to send email.'
    test=$(/usr/sbin/postconf mynetworks | grep '10.132.0.0/16' | wc -l)
    assertEquals $test 1
}


. shunit2-2.1.6/src/shunit2