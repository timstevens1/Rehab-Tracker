<?php
  // example request: http://path/to/resource/Example?method=sayHello&name=World

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
    
    //build and execute the query to select patientID
    $patientSelectQuery = "select pmkPatientID from tblPatient where pmkPatientID = ?";
    $patientSelectParams = array($name);
    $patientSelectResults = $thisDatabaseReader->select($patientSelectQuery, $patientSelectParams, 1, 0, 0, 0, false, false);
        
    
    //extract the results and write them to a string for packaging to JSON
    $resultString = "";
    foreach($results as $val){
        $resultString = $resultString.$val[0];
    }
    echo json_encode(array('pmkPatientID' => $resultString));
  }
  //Otherwise, test if we are receiving a POST request
  elseif($_SERVER['REQUEST_METHOD']=="POST")
  {
    //create the database writerObject
    $dbUserName = get_current_user() . '_writer';
    $whichPass = "w"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);

    //extract the sessions info from posted json
    $postedJson = file_get_contents('php://input');
    //convert JSON into array
    $sessionsData = json_decode($postedJson, TRUE);

    //loop through sessions to insert session data into db
    foreach($sessionsData as $postKey=>$session)
    {
      $pmkPatientID = $session["pmkPatientID"];
      $fldSessNum = $session["fldSessNum"];
      $fldSessionCompliance = $session["fldSessionCompliance"];
      $fldIntensity1 = $session["fldIntensity1"];
      $fldIntensity2 = $session["fldIntensity2"];
      $fldStartTime = $session["fldStartTime"];
      $fldEndTime = $session["fldEndTime"];
      $fldNote = $session["fldNote"];
      $fldDeviceSynced = $session["fldDeviceSynced"];

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
    } //end foreach session

    header( 'HTTP/1.1 201: Resource Created' ); 
  }
  else{
    header('HTTP/1.1 501: NOT SUPPORTED');
  }
?>