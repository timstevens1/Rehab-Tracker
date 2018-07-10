<?php
/** \file
 \brief Code for showing the navigation.
 
 This page displays the set of navigation links generated in nav.php.
 
 Check the [webpage] (https://rehabtracker.med.uvm.edu/physicianPortal/top.php).
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/physicianPortal/top.php).
 \cond
 **/
?>
<!DOCTYPE html>
<html lang="en">

    <!-- **********************     Body section      ********************** -->

    <?php
    session_start();
    if (!isset($_SESSION['DocID'])) {
        header("Location: login.php");
    }
    include "head.php";
    $tblPatient = 'tblPatient';
    $tblSession = 'tblSession';
    ?>

            <?php
            include "nav.php";
            ?>
    
        <div id ="container">
    
        
    <body>
        
        
        
            

            <!-- %%%%%%%%%%%%%%%%%%%%%%     Page header   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->





            <!-- %%%%%%%%%%%%%%%%%%%%% Ends Page header   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
