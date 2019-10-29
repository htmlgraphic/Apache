<!DOCTYPE html>
<html>
<head>
	<title>Coming soon!</title>
	<!-- Latest compiled and minified CSS -->
	<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
<style>
body {
	font-family: 'Open Sans', sans-serif; 
	font-weight: 300; 
	font-size: 14px; 
	text-align: center; 
	padding: 50px; 
}
div img#logo {
	margin: 0 auto 40px auto; 
	float: none;
}
.e {
	background-color: #ccf;
	width: 300px;
	font-weight: bold;
}
.v {
	background-color: #ddd;
	max-width: 300px;
	overflow-x: auto;
	word-wrap: break-word;
}
.h {
	background-color: #99c;
	font-weight: bold;
}
.center table {
	margin: 1em auto;
	text-align: left;
}
table {
	border-collapse: collapse;
	border: 0;
	width: 934px;
}
td, th {
	border: 1px solid #666;
	vertical-align: baseline;
	padding: 4px 5px;
}
img {
	float: right;
	border: 0;
}
.h h1 {
	font-size: 150%;
}
</style>

<?php
if (getenv('NODE_ENVIRONMENT')) {
	$node_env = getenv('NODE_ENVIRONMENT');
} else {
	$node_env = 'NOT SET';
} ?>
</head>
<body>
<?= "<!-- NODE_ENVIRONMENT=". getenv('NODE_ENVIRONMENT') ." -->"; ?>
<div class="container">
		<img id="logo" src="logo.png" width="200" />
		<h1><?= "Hello ".((getenv("NAME"))? $name:"World")."!"; ?></h1>

<div class="row center">
	<div class="col-xs-8 col-xs-offset-2">
		<table class="table table-bordered table-striped">
		<tbody>
		<tr>
			<th colspan="2">SYSTEM VARIABLES</th>
		</tr>
		<tr>
			<td class="text-right">HOSTNAME</td>
			<td class="text-left"><?= getenv('HOSTNAME') ?></td>
		</tr>
	<?php if ($node_env == 'dev') { ?>
		<?php if (getenv('MYSQL_PORT')) {?>
		<tr>
			<td class="text-right">MYSQL_PORT</td>
			<td class="text-left"><?= getenv('MYSQL_PORT'); ?></td>
		</tr>
		<?php } ?>
		<tr>
			<td class="text-right">NODE_ENVIRONMENT</td>
			<td class="text-left"><?= $node_env ?></td>
		</tr>
	<?php } ?>
		<tr>
			<td class="text-right">SMTP_HOST</td>
			<td class="text-left"><?= getenv('SMTP_HOST'); ?></td>
		</tr>
		<tr>
			<td class="text-right">max_execution_time</td>
			<td class="text-left"><?= ini_get('max_execution_time'); ?></td>
		</tr>
		<tr>
			<td class="text-right">memory_limit</td>
			<td class="text-left"><?= ini_get('memory_limit'); ?></td>
		</tr>
		<tr>
			<td class="text-right">upload_max_filesize</td>
			<td class="text-left"><?= ini_get('upload_max_filesize'); ?></td>
		</tr>
		<tr>
			<td class="text-right">post_max_size</td>
			<td class="text-left"><?= ini_get('post_max_size'); ?></td>
		</tr>
		<tr>
			<td class="text-right">max_input_time</td>
			<td class="text-left"><?= ini_get('max_input_time'); ?></td>
		</tr>
		</tbody>
		</table>
	</div>
</div>

	</div>
	<div style="clear: both;"></div>
<?php
	if (getenv("NODE_ENVIRONMENT") == 'dev') {
		ob_start();
		phpinfo();
		$pinfo = preg_replace( '%^.*<body>(.*)</body>.*$%ms','$1', ob_get_contents());
		ob_end_clean();
		echo $pinfo;
	}
?>
</div>
</body>
</html>
