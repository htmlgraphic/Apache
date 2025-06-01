#!/usr/bin/env bash
. /etc/environment

#### Extra breathing room
echo -e '\n'


setUp() {
    echo 'Running setup checks'
    if ! supervisorctl status apache2 | grep -q RUNNING; then
        fail 'Apache2 service is not running'
    fi
    if ! supervisorctl status postfix | grep -q RUNNING; then
        fail 'Postfix service is not running'
    fi
}

testSupervisordConfig() {
    echo 'Test supervisord configuration file'
    test=$(ls /etc/supervisor/supervisord.conf 2>/dev/null | wc -l)
    assertEquals "Supervisord config file should exist" 1 $test
    echo -e '\n'
}

testMySQLServiceRunning() {
    echo 'Test MySQL service status'
    test=$(docker exec ${CONTAINER_NAME} supervisorctl status | grep mysql | grep RUNNING | wc -l)
    assertEquals "MySQL service should be running under supervisord" 1 $test
    echo -e '\n'
}

testMySQLConnectivity() {
    echo 'Test MySQL connectivity'
    test=$(docker exec apache-db-1 mysql -u admin -pnew_password -h 127.0.0.1 -e "SELECT 1" 2>/dev/null | wc -l)
    assertEquals "MySQL should be accessible with admin credentials" 1 $test
    echo -e '\n'
}

testMySQLDatabase() {
    echo 'Test MySQL database existence'
    test=$(docker exec apache-db-1 mysql -u admin -pnew_password -h 127.0.0.1 -e "SHOW DATABASES LIKE 'htmlgraphic'" 2>/dev/null | grep htmlgraphic | wc -l)
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
    test=$(composer global show | grep 'laravel/installer' | wc -l)
    assertEquals "Laravel installer should be installed" 1 $test
    echo -e '\n'
}

testPhpDotenv() {
    echo 'Test vlucas/phpdotenv package'
    test=$(composer global show | grep 'vlucas/phpdotenv' | wc -l)
    assertEquals "vlucas/phpdotenv should be installed" 1 $test
    echo -e '\n'
}

testWPCLI() {
    echo 'Test WP-CLI installation'
    test=$(wp --version | grep 'WP-CLI' | wc -l)
    assertEquals "WP-CLI should be installed" 1 $test
    echo -e '\n'
}

testApacheServiceRunning() {
    echo 'Test Apache2 service status'
    test_systemd=$(systemctl is-active apache2 | grep 'active' | wc -l)
    test_supervisord=$(docker exec ${CONTAINER_NAME} supervisorctl status | grep apache2 | grep RUNNING | wc -l)
    assertEquals "Apache2 should be active via systemd" 1 $test_systemd
    assertEquals "Apache2 should be running under supervisord" 1 $test_supervisord
    echo -e '\n'
}

testPHPExtensionsInstallation() {
    echo 'Test PHP extensions installation'
    if ! command -v pecl >/dev/null; then
        fail "pecl command not found"
    fi
    for ext in mcrypt redis; do
        printf 'Checking PHP extension %s\n' "$ext"
        test=$(php -m | grep -w "$ext" | wc -l)
        assertEquals "PHP extension $ext should be installed" 1 $test
    done
    echo -e '\n'
}

testPHPVersion() {
    echo 'Test PHP version'
    test=$(php -v | grep 'PHP 8.3' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testApacheModules() {
    echo 'Test Apache modules'
    if ! command -v a2enmod >/dev/null; then
        fail "a2enmod command not found"
    fi
    for module in rewrite ssl; do
        printf 'Checking Apache module %s\n' "$module"
        test=$(apache2ctl -M | grep "${module}_module" | wc -l)
        assertEquals 1 $test
    done
    echo -e '\n'
}

testSSLConfiguration() {
    echo 'Test SSL configuration'
    test=$(cat /etc/apache2/sites-enabled/default-ssl.conf | grep 'SSLEngine on' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testPostfixServiceRunning() {
    echo 'Test Postfix service status'
    test_systemd=$(systemctl is-active postfix | grep 'active' | wc -l)
    test_supervisord=$(docker exec ${CONTAINER_NAME} supervisorctl status | grep postfix | grep RUNNING | wc -l)
    assertEquals "Postfix should be active via systemd" 1 $test_systemd
    assertEquals "Postfix should be running under supervisord" 1 $test_supervisord
    echo -e '\n'
}

testConfigFilesExist() {
    echo 'Test configuration files existence'
    for file in /etc/php/8.3/apache2/php.ini /etc/postfix/main.cf; do
        printf 'Checking file %s\n' "$file"
        test=$(ls $file | wc -l)
        assertEquals 1 $test
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
        assertEquals 1 $test
    done
    echo -e '\n'
}

testSecurityHeaders() {
    echo 'Test Apache security headers'
    for header in "X-Frame-Options: DENY" "X-Content-Type-Options: nosniff"; do
        printf 'Checking header %s\n' "$header"
        test=$(curl -s -I http://127.0.0.1 | grep -i "$header" | wc -l)
        assertEquals 1 $test
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
        test=$(dpkg -l | grep -w "$dep" | wc -l)
        assertEquals "Dependency $dep should be installed" 1 $test
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
    echo 'Test /var/www/html permissions'
    owner=$(stat -c '%U:%G' /var/www/html)
    file_perms=$(find /var/www/html -type f -exec stat -c '%a' {} \; | sort -u)
    dir_perms=$(find /var/www/html -type d -exec stat -c '%a' {} \; | sort -u)
    assertEquals "/var/www/html should be owned by www-data:www-data" "www-data:www-data" "$owner"
    assertEquals "Files in /var/www/html should have 644 permissions" "644" "$file_perms"
    assertEquals "Directories in /var/www/html should have 755 permissions" "755" "$dir_perms"
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
    echo 'Relay through SendGrid'
    test=$(/usr/sbin/postconf relayhost | grep 'htmlgraphic' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testHTTP() {
    echo 'Test Apache HTTP'
    test=$(/usr/bin/wget -q -O- http://127.0.0.1 | grep -w "Hello World\\!" | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testPHPModules() {
    echo 'Test PHP Modules'
    file="php_modules"
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        fail "File $file does not exist or is empty"
    fi
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            printf 'checking PHP module %s\n' "$line"
            test=$(/usr/bin/wget -q -O- http://127.0.0.1/php_extensions.php | grep -w "$line" | wc -l)
            assertEquals 1 $test
        fi
    done <"$file"
    echo -e '\n'
}

testPHPModulesCLI() {
    echo 'Test CLI PHP Modules'
    file="cli_php_modules"
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            printf 'checking CLI PHP module %s\n' "$line"
            module=$(php -i | grep "$line")
            test=$(echo $module | grep "$line" | wc -l)
            assertEquals 1 $test
        fi
    done <"$file"
    echo -e '\n'
}

testHTTPS() {
    echo 'Test Apache HTTPS'
    test=$(/usr/bin/wget -qO- --no-check-certificate https://127.0.0.1 | grep -w "Hello World\\!" | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testCLI_max_execution_time() {
    max_execution_time=$(php -i | grep 'max_execution_time')
    echo 'Test max_execution_time, currently set to "'$max_execution_time'"'
    test=$(echo $max_execution_time | grep 'max_execution_time => 0 => 0' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testCLI_MemoryLimit() {
    memory_limit=$(php -i | grep 'memory_limit')
    echo 'Test memory_limit, currently set to "'$memory_limit'"'
    test=$(echo $memory_limit | grep 'memory_limit => -1 => -1' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testCLI_upload_max_filesize() {
    upload_max_filesize=$(php -i | grep 'upload_max_filesize')
    echo 'Test upload_max_filesize, currently set to "'$upload_max_filesize'"'
    test=$(echo $upload_max_filesize | grep 'upload_max_filesize => 1000M => 1000M' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testCLI_post_max_size() {
    post_max_size=$(php -i | grep 'post_max_size')
    echo 'Test post_max_size, currently set to "'$post_max_size'"'
    test=$(echo $post_max_size | grep 'post_max_size => 1000M => 1000M' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testCLI_max_input_time() {
    max_input_time=$(php -i | grep 'max_input_time')
    echo 'Test max_input_time, currently set to "'$max_input_time'"'
    test=$(echo $max_input_time | grep 'max_input_time => -1 => -1' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testApache_max_execution_time() {
    max_execution_time=$(cat /etc/php/8.3/apache2/php.ini | grep 'max_execution_time')
    echo 'Test max_execution_time, currently set to "'$max_execution_time'"'
    test=$(echo $max_execution_time | grep 'max_execution_time = 300' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testApache_MemoryLimit() {
    memory_limit=$(cat /etc/php/8.3/apache2/php.ini | grep 'memory_limit')
    echo 'Test memory_limit, currently set to "'$memory_limit'"'
    test=$(echo $memory_limit | grep 'memory_limit = -1' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testApache_upload_max_filesize() {
    upload_max_filesize=$(cat /etc/php/8.3/apache2/php.ini | grep 'upload_max_filesize')
    echo 'Test upload_max_filesize, currently set to "'$upload_max_filesize'"'
    test=$(echo $upload_max_filesize | grep 'upload_max_filesize = 1000M' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testApache_post_max_size() {
    post_max_size=$(cat /etc/php/8.3/apache2/php.ini | grep 'post_max_size')
    echo 'Test post_max_size, currently set to "'$post_max_size'"'
    test=$(echo $post_max_size | grep 'post_max_size = 1000M' | wc -l)
    assertEquals 1 $test
    echo -e '\n'
}

testApache_max_input_time() {
    max_input_time=$(cat /etc/php/8.3/apache2/php.ini | grep 'max_input_time')
    echo 'Test max_input_time, currently set to "'$max_input_time'"'
    test=$(echo $max_input_time | grep 'max_input_time = 300' | wc -l)
    assertEquals 1 $test
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
    if [ -z "$CONTAINER_NAME" ]; then
        echo "Skipping NODE_ENVIRONMENT test: CONTAINER_NAME not set"
        return
    fi
    test=$(docker exec ${CONTAINER_NAME} /bin/bash -c "env | grep NODE_ENVIRONMENT" | wc -l)
    assertEquals "NODE_ENVIRONMENT should be set in Apache" 1 $test
    echo -e '\n'
}

echo "Test Summary: $(grep -c 'assert' build_tests.sh) tests executed"

. /opt/tests/shunit2-2.1.7/shunit2
