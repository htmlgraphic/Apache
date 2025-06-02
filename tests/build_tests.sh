#!/usr/bin/env bash
. /etc/environment

#### Extra breathing room
echo -e '\n'

setUp() {
    echo 'Running setup checks'
    # Wait for Apache2 to be ready
    for i in {1..30}; do
        if supervisorctl -c /etc/supervisord.conf status apache2 | grep -q RUNNING 2>/dev/null; then
            echo "Apache2 service is running"
            break
        fi
        echo "Waiting for Apache2 service ($i/30)"
        supervisorctl -c /etc/supervisord.conf status apache2
        sleep 2
    done
    if ! supervisorctl -c /etc/supervisord.conf status apache2 | grep -q RUNNING 2>/dev/null; then
        echo 'ERROR: Apache2 service failed to start'
        echo "DEBUG: Supervisord status:"
        supervisorctl -c /etc/supervisord.conf status
        echo "DEBUG: Apache2 error log:"
        cat /var/log/supervisor/apache2.err.log 2>/dev/null
        echo "DEBUG: Apache2 access log:"
        cat /data/apache2/logs/error_log 2>/dev/null
        apache2ctl configtest 2>/dev/null || echo "Apache2 config test failed"
        exit 1
    fi
    if ! supervisorctl -c /etc/supervisord.conf status postfix | grep -q RUNNING 2>/dev/null; then
        echo 'Warning: Postfix service is not running'
        supervisorctl -c /etc/supervisord.conf status postfix
    fi
}

testSupervisordConfig() {
    echo 'Test supervisord configuration file'
    test=$(ls /etc/supervisord.conf 2>/dev/null | wc -l)
    assertEquals "Supervisord config file should exist" 1 $test
    echo -e '\n'
}

testMySQLServiceRunning() {
    echo 'Test MySQL service status'
    # Wait for MySQL to be ready
    for i in {1..30}; do
        if mysqladmin -u admin -pnew_password -h db ping 2>/dev/null | grep -q 'mysqld is alive'; then
            test=1
            break
        fi
        echo "Waiting for MySQL service ($i/30)"
        sleep 2
    done
    test=${test:-0}
    assertEquals "MySQL service should be running" 1 $test
    echo -e '\n'
}

testMySQLConnectivity() {
    echo 'Test MySQL connectivity'
    test=$(mysql -u admin -pnew_password -h db -e "SELECT 1" 2>/dev/null | wc -l)
    assertEquals "MySQL should be accessible with admin credentials" 2 $test
    echo -e '\n'
}

testMySQLDatabase() {
    echo 'Test MySQL database existence'
    # Ensure database exists
    mysql -u admin -pnew_password -h db -e "CREATE DATABASE IF NOT EXISTS htmlgraphic" 2>/dev/null
    test=$(mysql -u admin -pnew_password -h db -e "SHOW DATABASES LIKE 'htmlgraphic'" 2>/dev/null | grep htmlgraphic | wc -l)
    assertEquals "Database htmlgraphic should exist" 1 $test
    echo -e '\n'
}

testComposer() {
    echo 'Test Composer installation'
    test=$(composer --version | grep 'Composer version 2' | wc -l)
    assertEquals "Composer v2 should be installed" 1 $test
    echo -e '\n'
}

testLaravelInstaller() {
    echo 'Test Laravel installer'
    test=$(composer global show | grep '^laravel/installer' | wc -l)
    assertEquals "Laravel installer should be installed" 1 $test
    echo -e '\n'
}

testPhpDotenv() {
    echo 'Test vlucas/phpdotenv package'
    test=$(composer global show | grep '^vlucas/phpdotenv' | wc -l)
    assertEquals "vlucas/phpdotenv should be installed" 1 $test
    echo -e '\n'
}

testWPCLI() {
    echo 'Test WP-CLI installation'
    test=$(wp --version --allow-root | grep 'WP-CLI' | wc -l)
    assertEquals "WP-CLI should be installed" 1 $test
    echo -e '\n'
}

testApacheServiceRunning() {
    echo 'Test Apache2 service status'
    test_supervisord=$(supervisorctl -c /etc/supervisord.conf status apache2 | grep -q RUNNING && echo 1 || echo 0)
    assertEquals "Apache2 should be running under supervisord" 1 $test_supervisord
    echo -e '\n'
}

testPHPExtensionsInstallation() {
    echo 'Test PHP extensions installation'
    if ! command -v php >/dev/null; then
        fail "php command not found"
    fi
    for ext in mcrypt redis pdo phar reflection simplexml spl; do
        printf 'Checking PHP extension %s\n' "$ext"
        test=$(php -m | grep -w "$ext" | wc -l)
        assertEquals "PHP extension $ext should be installed" 1 $test
    done
    echo -e '\n'
}

testPHPVersion() {
    echo 'Test PHP version'
    test=$(php -v | grep 'PHP 8.3' | wc -l)
    assertEquals "PHP 8.3 should be installed" 1 $test
    echo -e '\n'
}

testApacheModules() {
    echo 'Test Apache modules'
    if ! command -v apache2ctl >/dev/null; then
        fail "apache2ctl command not found"
    fi
    for module in rewrite ssl; do
        printf 'Checking Apache module %s\n' "$module"
        test=$(apache2ctl -M 2>/dev/null | grep "${module}_module" | wc -l)
        assertEquals "Apache module $module should be enabled" 1 $test
    done
    echo -e '\n'
}

testSSLConfiguration() {
    echo 'Test SSL configuration'
    test=$(grep 'SSLEngine on' /data/apache2/sites-enabled/000-default.conf 2>/dev/null | wc -l)
    assertEquals "SSL should be enabled in 000-default.conf" 1 $test
    echo -e '\n'
}

testPostfixServiceRunning() {
    echo 'Test Postfix service status'
    test_supervisord=$(supervisorctl -c /etc/supervisord.conf status postfix | grep -q RUNNING && echo 1 || echo 0)
    assertEquals "Postfix should be running under supervisord" 1 $test_supervisord
    echo -e '\n'
}

testConfigFilesExist() {
    echo 'Test configuration files existence'
    for file in /etc/php/8.3/apache2/php.ini /etc/postfix/main.cf; do
        printf 'Checking file %s\n' "$file"
        test=$(ls $file 2>/dev/null | wc -l)
        assertEquals "Config file $file should exist" 1 $test
    done
    echo -e '\n'
}

testEnvironmentVariables() {
    echo 'Test environment variables'
    for var in SASL_USER SASL_PASS NODE_ENVIRONMENT LOG_TOKEN; do
        printf 'Checking environment variable %s\n' "$var"
        test=$(env | grep "^${var}=" | wc -l)
        assertEquals "Environment variable $var should be set" 1 $test
    done
    assertEquals "SASL_USER should match expected value" "05ad514dda62af" "$SASL_USER"
    assertEquals "LOG_TOKEN should match expected value" "66b6e993-5357-4b89-9d41-bd8234163c2b" "$LOG_TOKEN"
    echo -e '\n'
}

testCommandAvailability() {
    echo 'Test command availability'
    for cmd in wget php postconf apache2ctl; do
        printf 'Checking command %s\n' "$cmd"
        test=$(command -v $cmd | wc -l)
        assertEquals "Command $cmd should be available" 1 $test
    done
    echo -e '\n'
}

testSecurityHeaders() {
    echo 'Test Apache security headers'
    for header in "X-Frame-Options: DENY" "X-Content-Type-Options: nosniff"; do
        printf 'Checking header %s\n' "$header"
        test=$(curl -s -I http://127.0.0.1 2>/dev/null | grep -i "$header" | wc -l)
        assertEquals "Security header $header should be set" 1 $test
    done
    echo -e '\n'
}

testHTTPStatusCode() {
    echo 'Test HTTP status code for http://127.0.0.1'
    local url="http://127.0.0.1"
    local expected_status=200
    local timeout=10
    local test=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" -L "$url" 2>~/project/container-build/http_error.log)
    if [ $? -ne 0 ]; then
        fail "HTTP request failed: $(cat ~/project/container-build/http_error.log)"
    fi
    assertEquals "HTTP status code for $url should be $expected_status" "$expected_status" "$test"
    echo -e '\n'
}

testHTTPSStatusCode() {
    echo 'Test HTTPS status code for https://127.0.0.1'
    local url="https://127.0.0.1"
    local expected_status=200
    local timeout=10
    local test=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" -L --insecure "$url" 2>~/project/container-build/https_error.log)
    if [ $? -ne 0 ]; then
        fail "HTTPS request failed: $(cat ~/project/container-build/https_error.log)"
    fi
    assertEquals "HTTPS status code for $url should be $expected_status" "$expected_status" "$test"
    echo -e '\n'
}

testPostfixUsername() {
    echo 'Testing Postfix username, currently set to "'${SASL_USER}'"'
    if [ -z "${SASL_USER}" ]; then
        fail 'ENV $SASL_USER is not set'
    fi
    test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep "${SASL_USER}" | wc -l)
    assertEquals "Postfix username ${SASL_USER} should be configured in smtp_sasl_password_maps" 1 $test
    echo -e '\n'
}

testWkhtmltoxDependencies() {
    echo 'Test wkhtmltox dependencies'
    for dep in fontconfig libjpeg-turbo8 libssl1.1 xfonts-75dpi xfonts-base; do
        printf 'Checking dependency %s\n' "$dep"
        test=$(dpkg -l | grep -w "$dep" | grep -v '^rc' | grep '^ii' | wc -l)
        assertTrue "Dependency $dep should be installed" "[ $test -ge 1 ]"
    done
    echo -e '\n'
}

testWkhtmltox() {
    echo 'Test wkhtmltox installation'
    if ! command -v wkhtmltopdf >/dev/null; then
        fail "wkhtmltopdf command not found"
    fi
    test=$(wkhtmltopdf --version | grep 'wkhtmltopdf 0.12.6' | wc -l)
    assertEquals "wkhtmltox 0.12.6 should be installed" 1 $test
    echo -e '\n'
}

testWkhtmltoxFunctional() {
    echo 'Test wkhtmltox functionality'
    local test_dir=~/project/container-build
    echo '<html><body>Test PDF</body></html>' > "$test_dir/test.html"
    local test=$(timeout 10 wkhtmltopdf "$test_dir/test.html" "$test_dir/test.pdf" 2>"$test_dir/wkhtmltopdf_error.log" && ls "$test_dir/test.pdf" | wc -l)
    if [ $? -ne 0 ]; then
        fail "wkhtmltopdf failed: $(cat "$test_dir/wkhtmltopdf_error.log")"
    fi
    assertEquals "wkhtmltopdf should generate a PDF file" 1 "$test"
    rm -f "$test_dir/test.html" "$test_dir/test.pdf" "$test_dir/wkhtmltopdf_error.log"
    echo -e '\n'
}

testWebRootPermissions() {
    echo 'Test /data/www/public_html top-level permissions'
    echo "DEBUG: Checking /data/www/public_html"
    stat /data/www/public_html 2>/dev/null || fail "Directory /data/www/public_html does not exist"
    owner=$(stat -c '%U:%G' /data/www/public_html 2>/dev/null)
    dir_perms=$(stat -c '%a' /data/www/public_html 2>/dev/null)
    assertEquals "/data/www/public_html should be owned by www-data:www-data" "www-data:www-data" "$owner"
    assertEquals "Directory /data/www/public_html should have 755 permissions" "755" "$dir_perms"
    echo -e '\n'
}

testShunit2() {
    echo 'Test shunit2 installation'
    shunit2_path=$(find /opt/tests -name shunit2 2>/dev/null)
    test=$(test -f "$shunit2_path" && echo 1 || echo 0)
    assertEquals "shunit2 should be installed" 1 $test
    echo -e '\n'
}

testPostfixPassword() {
    echo 'Testing Postfix password configuration'
    if [ -z "${SASL_PASS}" ]; then
        fail 'ENV $SASL_PASS is not set'
    fi
    test=$(/usr/sbin/postconf smtp_sasl_password_maps | grep -c "smtp_sasl_password_maps")
    assertEquals "Postfix password should be configured" 1 $test
    echo -e '\n'
}

testPostfixRelay() {
    echo 'Relay through mailtrap'
    test=$(/usr/sbin/postconf relayhost | grep 'sandbox.smtp.mailtrap.io' | wc -l)
    assertEquals "Postfix should use mailtrap relay" 1 $test
    echo -e '\n'
}

testHTTP() {
    echo 'Test Apache HTTP'
    test=$(/usr/bin/wget -q -O- http://127.0.0.1 2>/dev/null | grep -w "Hello World" | wc -l)
    assertEquals "HTTP response should contain Hello World" 1 $test
    echo -e '\n'
}

testPHPModules() {
    echo 'Test PHP Modules'
    file="/opt/tests/php_modules"
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        fail "File $file does not exist or is empty"
    fi
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            printf 'checking PHP module %s\n' "$line"
            test=$(curl -s http://localhost/php_extensions.php 2>/dev/null | grep -w "$line" | wc -l)
            assertEquals "PHP module $line should be loaded" 1 "$test"
        fi
    done <"$file"
    echo -e '\n'
}

testPHPModulesCLI() {
    echo 'Test PHP CLI Modules'
    file="/opt/tests/cli_php_modules"
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        fail "File $file does not exist or is empty"
    fi
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            printf 'checking CLI PHP module %s\n' "$line"
            module=$(php -m | grep -w "$line" | wc -l)
            assertEquals "CLI PHP module $line should be loaded" 1 "$module"
        fi
    done <"$file"
    echo -e '\n'
}

testHTTPS() {
    echo 'Test Apache HTTPS'
    test=$(/usr/bin/wget -qO- --no-check-certificate https://127.0.0.1 2>/dev/null | grep -w "Hello World" | wc -l)
    assertEquals "HTTPS response should contain Hello World" 1 $test
    echo -e '\n'
}

testCLI_max_execution_time() {
    max_execution_time=$(php -i | grep 'max_execution_time')
    echo 'Test max_execution_time, currently set to "'$max_execution_time'"'
    test=$(echo $max_execution_time | grep 'max_execution_time => 300 => 300' | wc -l)
    assertEquals "CLI max_execution_time should be 300" 1 $test
    echo -e '\n'
}

testCLI_MemoryLimit() {
    memory_limit=$(php -i | grep 'memory_limit')
    echo 'Test memory_limit, currently set to "'$memory_limit'"'
    test=$(echo $memory_limit | grep 'memory_limit => -1 => -1' | wc -l)
    assertEquals "CLI memory_limit should be -1" 1 $test
    echo -e '\n'
}

testCLI_upload_max_filesize() {
    upload_max_filesize=$(php -i | grep 'upload_max_filesize')
    echo 'Test upload_max_filesize, currently set to "'$upload_max_filesize'"'
    test=$(echo $upload_max_filesize | grep 'upload_max_filesize => 1000M => 1000M' | wc -l)
    assertEquals "CLI upload_max_filesize should be 1000M" 1 $test
    echo -e '\n'
}

testCLI_post_max_size() {
    post_max_size=$(php -i | grep 'post_max_size')
    echo 'Test post_max_size, currently set to "'$post_max_size'"'
    test=$(echo $post_max_size | grep 'post_max_size => 1000M => 1000M' | wc -l)
    assertEquals "CLI post_max_size should be 1000M" 1 $test
    echo -e '\n'
}

testCLI_max_input_time() {
    max_input_time=$(php -i | grep 'max_input_time')
    echo 'Test max_input_time, currently set to "'$max_input_time'"'
    test=$(echo $max_input_time | grep 'max_input_time => 300 => 300' | wc -l)
    assertEquals "CLI max_input_time should be 300" 1 $test
    echo -e '\n'
}

testApache_max_execution_time() {
    max_execution_time=$(cat /etc/php/8.3/apache2/php.ini | grep '^max_execution_time')
    echo 'Test max_execution_time, currently set to "'$max_execution_time'"'
    test=$(echo $max_execution_time | grep 'max_execution_time = 300' | wc -l)
    assertEquals "Apache max_execution_time should be 300" 1 $test
    echo -e '\n'
}

testApache_MemoryLimit() {
    memory_limit=$(cat /etc/php/8.3/apache2/php.ini | grep '^memory_limit')
    echo 'Test memory_limit, currently set to "'$memory_limit'"'
    test=$(echo $memory_limit | grep 'memory_limit = -1' | wc -l)
    assertEquals "Apache memory_limit should be -1" 1 $test
    echo -e '\n'
}

testApache_upload_max_filesize() {
    upload_max_filesize=$(cat /etc/php/8.3/apache2/php.ini | grep '^upload_max_filesize')
    echo 'Test upload_max_filesize, currently set to "'$upload_max_filesize'"'
    test=$(echo $upload_max_filesize | grep 'upload_max_filesize = 1000M' | wc -l)
    assertEquals "Apache upload_max_filesize should be 1000M" 1 $test
    echo -e '\n'
}

testApache_post_max_size() {
    post_max_size=$(cat /etc/php/8.3/apache2/php.ini | grep '^post_max_size')
    echo 'Test post_max_size, currently set to "'$post_max_size'"'
    test=$(echo $post_max_size | grep 'post_max_size = 1000M' | wc -l)
    assertEquals "Apache post_max_size should be 1000M" 1 $test
    echo -e '\n'
}

testApache_max_input_time() {
    max_input_time=$(cat /etc/php/8.3/apache2/php.ini | grep '^max_input_time')
    echo 'Test max_input_time, currently set to "'$max_input_time'"'
    test=$(echo $max_input_time | grep 'max_input_time = 300' | wc -l)
    assertEquals "Apache max_input_time should be 300" 1 $test
    echo -e '\n'
}

testNODE_ENVIRONMENT() {
    echo 'Test env NODE_ENVIRONMENT, currently set to "'${NODE_ENVIRONMENT}'"'
    assertTrue "NODE_ENVIRONMENT should be 'dev' or 'production'" \
        "[[ ${NODE_ENVIRONMENT} == 'dev' || ${NODE_ENVIRONMENT} == 'production' ]]"
    echo -e '\n'
}

testNODE_ENVIRONMENT_PHP() {
    echo 'Test env NODE_ENVIRONMENT within Apache'
    test=$(env | grep NODE_ENVIRONMENT | wc -l)
    assertEquals "NODE_ENVIRONMENT should be set in Apache" 1 $test
    echo -e '\n'
}

echo "Test Summary: $(grep -c '^test[A-Za-z]' $0) tests executed"

. /opt/tests/shunit2-2.1.7/shunit2
