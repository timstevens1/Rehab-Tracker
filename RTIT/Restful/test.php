<?php
  require_once realpath("../constants.php");
  require_once "Database.php";
  
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
    print_r($Notifications);
    echo json_encode($Notifications,JSON_PRETTY_PRINT);
    echo json_last_error();
    echo "\n";