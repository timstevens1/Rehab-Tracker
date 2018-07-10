<?php
/** \file
 \brief Page for clinician to log in.
 
 This page allows a new physician to log in by typing ID and password and jumps to the index page if the information is valid.
 
 Check the [webpage] (https://rehabtracker.med.uvm.edu/physicianPortal/login.php).
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/physicianPortal/login.php).
 \cond
 **/
    
session_start();
include 'dbh.php';
require_once'head.php';
if (isset($_POST["submit"])) {
    $DocID = mysqli_real_escape_string($DBcon, $_POST['DocID']);
    $fldPass = mysqli_real_escape_string($DBcon, $_POST['fldPass']);
    $sel_doc = "SELECT * FROM tblDoctor WHERE DocID = '$DocID' AND fldPass = '$fldPass'";
    $run_doc = mysqli_query($DBcon, $sel_doc);
    $check_doc = mysqli_num_rows($run_doc);
    if ($check_doc > 0) {
        $_SESSION['DocID'] = $DocID;

        $check_Admin = "SELECT fldAdmin FROM tblDoctor WHERE DocID = '". $_SESSION['DocID']."'";
        $admin = $thisDatabaseReader->select($check_Admin, "", 1, 0, 2, 0, false, false);
     $_SESSION['fldAdmin']= $admin[0][0];
     
        echo "<script>window.open('index.php','_self')</script>";
    } else {
        echo "<script>alert('Email or password is not correct, try again!')</script>";
    }
//    $isAdmin = false;
}
?>
<!doctype html>
<html>

    <head>
        <title>Login</title>
        <link rel="stylesheet" type="text/css" href="style.css">
    </head>
    <body>


        <div id="container">
            <!--            <div id="logo">
                            <img src="Running.jpeg" alt="Run">
                            <h1>Rehab Compliance Portal</h1>-->

            <!--            </div>-->

            <!--            <div>-->
            <!--                <div id="login">-->

            <form action="" method="post">
                <p></p>                    
                <label>Doctor ID:</label><input type="text" name="DocID"><br/>
                <label>Password:</label><input type="password" name="fldPass"><br/>
                <input type="submit" value="Login" name="submit"><br/>
            </form>

            <!--                </div>-->
            <!--            </div>-->
        </div>

    </body>
</html>
