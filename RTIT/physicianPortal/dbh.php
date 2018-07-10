<?php
/** \file
 \brief Page for connecting the database.
 
 This page checks the database information and connect the physician portal to it.
 
 There is no webpage for this. The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/physicianPortal/dbh.php).
 
 \cond
 **/
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
