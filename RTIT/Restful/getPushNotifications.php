<?php
/** \file
 \brief Code for retrieving push notifications that have not been delivered or updating notifications as delivered.
 
 This code retrieves all push notifications stored in the database that have not been delivered for a GET request or marks delivered push notifications for a POST request.
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/getPustNotifications.php).
 \cond
 **/
  require_once realpath("../constants.php");
  require_once "Database.php";
  
  //First, detect if we are receiving a GET request
  if($_SERVER['REQUEST_METHOD']=="GET")
  { 
    //extract the username from the header
    
    //instantiate the database connection
    $dbUserName = DB_WRITER;
    $whichPass = "r"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseReader = new Database($dbUserName, $whichPass, $dbName);
    
    //build and execute the query to select all sessions for user
    $pushSelectionQuery = "SELECT pmkPushID, fnkPatientID, fnkMessageID FROM tblPush WHERE fldDelivered =0";
    $pushSelections = $thisDatabaseReader->select($pushSelectionQuery,"", 1, 0, 0, 0, true, false);
    //extract the results and write them to JSON
    $UDIDSelectionQuery = "SELECT UDID FROM tblPatient WHERE pmkPatientID=?";
    $MessageSelectionQuery = "SELECT fldMessageString FROM tblNotifications WHERE pmkMessageID=?";
    $Notifications = array();
    foreach($pushSelections as $push){
      $UDID = $thisDatabaseReader->select($UDIDSelectionQuery,array($push["fnkPatientID"]), 1, 0, 0, 0, true, false);
      $push["UDID"] = $UDID[0]["UDID"];
      if ($push["UDID"] != ""){
        $Message = $thisDatabaseReader->select($MessageSelectionQuery,array($push["fnkMessageID"]), 1, 0, 0, 0, true, false);
        $push["Message"] = utf8_encode($Message[0][0]);
        $push = array_diff_key($push,[0=>"",1=>"",2=>"","fnkPatientID"=>"","fnkMessageID"=>""]);
        $Notifications[] = $push;
      }
    }
    header('Content-Type: application/json');
    echo json_encode($Notifications);

  }
    elseif($_SERVER['REQUEST_METHOD']=="POST")
  {
    //extract the username and the age variable from the header
    
    $data = json_decode(file_get_contents('php://input'), true);
    $inQuery = implode(',', array_fill(0, count($data["pushed"]), '?'));
    $query = "UPDATE tblPush SET fldDelivered=1 WHERE pmkPushID IN (".$inQuery.")";
    //convert fldSessNum to new format (with patientID prefix)
    
    //create the database writerObject
    $dbUserName = DB_WRITER;
    $whichPass = "w"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);
    echo $query;
    $deviceSynchedUpdateResult = $thisDatabaseWriter->update($query, $data["pushed"], 1,0,0,0,false,false);
    echo($deviceSynchedUpdateResult);
    header( 'HTTP/1.1 201: Resource Created' ); 
  }
  else{
    header('HTTP/1.1 501: NOT SUPPORTED');
  }
