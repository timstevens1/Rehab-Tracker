<?php
/** \file
 \brief Code for retrieving a patient's maximum session number or inserting a new session.
 
 This code retrieves a patient's maximum session number for a GET request or inserts a session of the patient for a POST request.
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/sync.php).
 \cond
 **/
    
  // example request: http://path/to/resource/Example?method=sayHello&name=World

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
    
    //build and execute the query to select all sessionIDs for user
    $userSessionsSelectQuery = "select fldSessNum from tblSession where pmkPatientID = ?";
    $userSessionsSelectParams = array($name);
    $userSessionsSelectResults = $thisDatabaseReader->select($userSessionsSelectQuery, $userSessionsSelectParams, 1, 0, 0, 0, false, false);
    
    //extract the results and write them to a string for packaging to JSON
    if (empty($userSessionsSelectResults)) {
      $maxUserSessionNumber = 0;
    } else {
      $userSessionNumbers = array();
      foreach($userSessionsSelectResults as $userSessionResult){
        $userSessionID = $userSessionResult[0];
        $userPrefixCharCount = strlen($name) + 1;
        $userSessionNumber = substr($userSessionID, $userPrefixCharCount);
        $userSessionNumbers[] = (int)$userSessionNumber;
      }
      $maxUserSessionNumber = max($userSessionNumbers);
    }
    echo json_encode(array('maxUserSessionNumber' => $maxUserSessionNumber));
  }
  //Otherwise, test if we are receiving a POST request
  elseif($_SERVER['REQUEST_METHOD']=="POST")
  {
    //create the database writerObject
    $dbUserName = DB_WRITER;
    $whichPass = "w"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);

    //extract the sessions info from posted json
    $postedJson = file_get_contents('php://input');
    //convert JSON into array
    $sessionsData = json_decode($postedJson, TRUE);

    $compliant = FALSE;
    //loop through sessions to insert session data into db
    $sessionCount = 0;
    foreach($sessionsData as $postKey=>$session)
    {
      //$session = json_decode($sessionJson, TRUE);
      $pmkPatientID = $session["pmkPatientID"];
      $fldSessNum = $session["fldSessNum"];
      $fldSessionCompliance = $session["fldSessionCompliance"];
      $fldIntensity1 = $session["fldIntensity1"];
      $fldIntensity2 = $session["fldIntensity2"];
      $fldStartTime = $session["fldStartTime"];
      $fldEndTime = $session["fldEndTime"];
      $fldNote = $session["fldNote"];
      $fldDeviceSynced = $session["fldDeviceSynced"];

      if((strtotime($fldEndTime) - strtotime($fldStartTime)) >= 2400){
        $compliant = TRUE;
        $sessionCount = $sessionCount + 1;
      }
      //convert fldSessNum to new format (with patientID prefix)
      $fldSessNum = $pmkPatientID."_".$fldSessNum;

      //build and execute the query to insert session entry
      $sessionInsertQuery = "INSERT INTO tblSession(pmkPatientID, 
                                                    fldSessNum, 
                                                    fldSessionCompliance, 
                                                    fldIntensity1, 
                                                    fldIntensity2,
                                                    fldStartTime,
                                                    fldEndTime, 
                                                    fldNote,
                                                    fldDeviceSynced) 
                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
      $sessionInsertParams = array($pmkPatientID, $fldSessNum, $fldSessionCompliance, $fldIntensity1, $fldIntensity2, $fldStartTime, $fldEndTime, $fldNote, $fldDeviceSynced);
      $sessionInsertResult = $thisDatabaseWriter->insert($sessionInsertQuery, $sessionInsertParams, 0,0,0,0,false,false);
      
      //build and execute query to update fldDeviceSynced date for patient
      $deviceSyncedUpdateQuery= "Update tblPatient set fldDeviceSynced = ? where pmkPatientID= ?";
      $deviceSyncedUpdateParams = array($fldDeviceSynced,$pmkPatientID);
      $deviceSyncedUpdateResult = $thisDatabaseWriter->update($deviceSyncedUpdateQuery, $deviceSyncedUpdateParams, 1,0,0,0,false,false);
    }
     //end foreach session
    $success = $thisDatabaseWriter -> update("UPDATE tblPatient set fldWeekCompliance = fldWeekCompliance + ? Where pmkPatientID = ?", array($sessionCount,$pmkPatientID),1,0,0,0,false,false);
    if($compliant){
      $insertionQueryComp = 'INSERT INTO tblPush (fnkPatientID, fnkMessageID, fldDelivered) VALUES(?,?,?)';
      //encapsulate the patient data
      $patientDataComp = array($pmkPatientID, rand(1,21),0);
      $insertionNonComp = $thisDatabaseWriter -> insert($insertionQueryComp, $patientDataComp, 0, 0, 0, 0, false, false);
    }

    header( 'HTTP/1.1 201: Resource Created' ); 
  }
  else{
    header('HTTP/1.1 501: NOT SUPPORTED');
  }
?>
