<?php
// DO NOT MODIFY THIS FILE IT IS CREATED EACH TIME THE INSTANCE IS STARTED
if (getenv("NODE_ENVIRONMENT") == 'dev') {

	# Ensure that chars show in browser correctly.
	header('Content-Type: text/plain; charset=utf-8');

	// The following modules, should exist in the build
	$modules = 'apache2handler,calendar,ctype,curl,date,dom,exif,fileinfo,filter,ftp,gd,gettext,hash,iconv,imagick,json,libxml,mbstring,mcrypt,mysqli,mysqlnd,openssl,pcre,pdo,pdo_mysql,phar,posix,readline,reflection,session,shmop,simplexml,sockets,spl,standard,sysvmsg,sysvsem,sysvshm,tokenizer,xml,xmlreader,xmlwriter,xsl,opcache.enable,zip,zlib, mod_deflate, mod_filter';

	$mods_check = array_map('trim', explode(",",$modules));

	// Sort alphabetically.
	sort($mods_check);

	// Get regular (non-Zend) extensions.
	$apache_modules = apache_get_modules();
	$mods = get_loaded_extensions();

	// 'zend_extensions' param only introduced in PHP 5.2.4,
	// setting the param returns NULL in PHP 5.1.
	$zend_mods = get_loaded_extensions(true);
	if ($zend_mods) {
	    $mods = array_merge($mods, $zend_mods);
	}


	if ($apache_modules) {
	    $mods = array_merge($mods, $apache_modules);
	}

	$mods = array_map('strtolower', $mods);
	// Remove duplicates.
	$mods = array_unique($mods);
	print 'Enabled Module / Extensions: (✓ indicates required)' ."\n\n";

	#
	# Output modules table.
	#
	foreach($mods as $mod) {
	    # Search for Apache module, does it exist
	    printf('%-18s', $mod);

	    if(in_array($mod, $mods_check)) {
	        echo '|    ✓    ';
	    } else {
	        echo '|         ';
	    }
	    echo "\n";
	}

} else {
	echo 'NODE_ENVIRONMENT: <strong>'. getenv("NODE_ENVIRONMENT") .'</strong>';
}

echo '<br /><br /><a href="https://github.com/htmlgraphic/Apache">GitHub</a>';
