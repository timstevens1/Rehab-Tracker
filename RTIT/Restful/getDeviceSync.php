<?php
/** \file
 \brief Code for retrieving a patient's all sessions.
 
 This code retrieves a patient's sessions from the database for a GET request.
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/getDeviceSync.php).
 \cond
 **/
  require_once realpath("../constants.php");
  require_once "Database.php";
  
  //First, detect if we are receiving a GET request
  if($_SERVER['REQUEST_METHOD']=="GET")
  { 
    //extract the username from the header
    $name = $_GET['pmkPatientID'];
    
    //instantiate the database connection
    $dbUserName = DB_WRITER;
    $whichPass = "r"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseReader = new Database($dbUserName, $whichPass, $dbName);
    
    //build and execute the query to select all sessions for user
    $userSessionsSelectQuery = "select fldDeviceSynced,fldWeekCompliance from tblPatient where pmkPatientID = ?";
    $userSessionsSelectParams = array($name);
    $userSessionsSelectResults = $thisDatabaseReader->select($userSessionsSelectQuery, $userSessionsSelectParams, 1, 0, 0, 0, false, false);
    
    //extract the results and write them to JSON
    echo json_encode(array('sync' => $userSessionsSelectResults[0][0], 'count'=> $userSessionsSelectResults[0][1]));
  }
  else{
    header('HTTP/1.1 501: NOT SUPPORTED');
  }
