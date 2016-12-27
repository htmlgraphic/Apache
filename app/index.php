<!DOCTYPE html>
<html>
<head>
	<title>Coming soon!</title>
	<link href='//fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css'>
	<style>
	body {text-align: center; padding: 50px; font-family: "Open Sans","Helvetica Neue",Helvetica,Arial,sans-serif;}
	div img#logo {margin: 0 auto 40px auto; float: none;}
	</style>
</head>
<body>
	<div>
		<img id="logo" src="logo.png" width="200" />
		<h1><?= "Hello ".((getenv("NAME"))? $name:"World")."!"; ?></h1>
		<?php if (getenv('HOSTNAME')) {?><h3>My hostname is <?= getenv('HOSTNAME'); ?></h3><?php } ?>
		<?php if (getenv('MYSQL_PORT')) {?>MySQL <strong><?= getenv('MYSQL_PORT'); ?></strong><?php } ?>
		<p>Current file: <strong><?= __FILE__ ?></strong></p>
		<p>SMTP Host: <strong><?= getenv('SMTP_HOST'); ?></strong></p>
		<?php if (getenv('NODE_ENVIRONMENT')) { ?>
		<p>NODE_ENVIRONMENT: <?= getenv('NODE_ENVIRONMENT') ?></p>
		<?php } else { ?>
		<p>NODE_ENVIRONMENT: NOT SET</p>
		<?php } ?>
	</div>
	<div style="clear: both;"></div>
<?php
	if (getenv("NODE_ENVIRONMENT") == 'dev') {
		phpinfo();
	}
?>
</body>
</html>
