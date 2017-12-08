<?php
  require_once "constants.php";
  require_once "pass.php";
  require_once "Database.php";
  
  //First, detect if we are receiving a GET request
  if($_SERVER['REQUEST_METHOD']=="GET")
  { 
    //extract the username from the header
    $name = $_GET['pmkPatientID'];
    
    //instantiate the database connection
    $dbUserName = get_current_user() . '_reader';
    $whichPass = "r"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseReader = new Database($dbUserName, $whichPass, $dbName);
    
    //build and execute the query to select all sessions for user
    $userSessionsSelectQuery = "select fldSessNum, fldIntensity1, fldIntensity2, fldStartTime, fldEndTime, fldNote, fldDeviceSynced from tblSession where pmkPatientID = ?";
    $userSessionsSelectParams = array($name);
    $userSessionsSelectResults = $thisDatabaseReader->select($userSessionsSelectQuery, $userSessionsSelectParams, 1, 0, 0, 0, false, false);
    
    //extract the results and write them to JSON
    echo json_encode(array('userSessions' => $userSessionsSelectResults));
  }
  else{
    header('HTTP/1.1 501: NOT SUPPORTED');
  }
?>
