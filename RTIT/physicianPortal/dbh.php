<?php
require_once realpath("../constants.php");
require_once realpath("../pass.php");
$DBhost = DB_HOST;
$DBuser = DB_ADMIN;
$DBpass = $dbAdmin;
$DBname = DATABASE_NAME;
$DBcon = new MySQLi($DBhost,$DBuser,$DBpass,$DBname);
if ($DBcon->connect_errno) {
         die("ERROR : -> ".$DBcon->connect_error);
     }
