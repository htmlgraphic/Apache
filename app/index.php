<!DOCTYPE html>
<html>
<head>
	<title>Coming soon!</title>
	<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css'>
	<style>
	body {background-color: white; text-align: center; padding: 50px; font-family: "Open Sans","Helvetica Neue",Helvetica,Arial,sans-serif;}
	#logo {margin-bottom: 40px;}
	</style>
</head>
<body>
	<img id="logo" src="logo.png" width="200" />

	<h1><?= "Hello ".((getenv("NAME"))? $name:"World")."!"; ?></h1>
	<?php if (getenv('HOSTNAME')) {?><h3>My hostname is <?= getenv('HOSTNAME'); ?></h3><?php } ?>
	<?php if (getenv('MYSQL_PORT')) {?>MySQL <strong><?= getenv('MYSQL_PORT'); ?></strong><?php } ?>
	<p>Current file: <strong><?= __FILE__ ?></strong></p>
	<?php if (getenv('NODE_ENVIRONMENT')) { ?>
	<p>NODE_ENVIRONMENT: <strong><?= getenv('NODE_ENVIRONMENT') ?></strong></p>
	<?php } else { ?>
	<p>NODE_ENVIRONMENT: <strong>NOT SET</strong></p>
	<?php }

	//phpinfo();
?>
</body>
</html>
