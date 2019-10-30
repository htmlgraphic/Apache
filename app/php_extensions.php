<?php
# Ensure that chars show in browser correctly.
header('Content-Type: text/plain; charset=utf-8');

// The following modules, should exist in the build
$mods_check = explode(',', 'apache2handler,apcu,calendar,ctype,curl,date,dom,exif,fileinfo,filter,ftp,gd,gettext,hash,iconv,imagick,json,libxml,mbstring,mcrypt,mysqli,mysqlnd,openssl,pcre,pdo,pdo_mysql,phar,posix,readline,reflection,session,shmop,simplexml,sockets,spl,standard,sysvmsg,sysvsem,sysvshm,tokenizer,wddx,xml,xmlreader,xmlwriter,xsl,zend opcache,zip,zlib');

// Sort alphabetically.
sort($mods_check);

// Get regular (non-Zend) extensions.
$mods = get_loaded_extensions();

// 'zend_extensions' param only introduced in PHP 5.2.4,
// setting the param returns NULL in PHP 5.1.
$zend_mods = get_loaded_extensions(true);
if ($zend_mods) {
    $mods = array_merge($mods, $zend_mods);
}
$mods = array_map('strtolower', $mods);
// Remove duplicates.
$mods = array_unique($mods);

print 'Extensions:    ' ."\n\n";

#
# Output modules table.
#
foreach($mods_check as $mod) {
    # Search for Apache module, does it exist
    printf('%-16s ', $mod);
    if(in_array($mod, $mods)) {
        echo '|    ✓    ';
    } else {
        echo '|         ';
    }
    echo "\n";
}
