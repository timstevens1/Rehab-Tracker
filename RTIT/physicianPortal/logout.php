<?php
/** \file
 \brief Code for clearing current login status and jumping to the login page.
 
 This page allows a physician to log out and log in again by typing ID and password.
 
There is no webpage for this.
The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/physicianPortal/logout.php).
 \cond
 **/
    
session_start();
session_destroy();
echo "<script>window.open('login.php','_self')</script>";
?>

>
