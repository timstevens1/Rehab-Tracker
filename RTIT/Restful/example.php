<?php
  // example request: http://path/to/resource/Example?method=sayHello&name=World

  require_once realpath("../constants.php");
  require_once "Database.php";
  
  //First, detect if we are receiving a GET request
  if($_SERVER['REQUEST_METHOD']=="GET")
  { 
    //extract the username from the header
    $name = $_GET['pmkPatientID'];
    
    //instantiate the database connection
    $dbUserName = DB_READER;
    $whichPass = "r"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseReader = new Database($dbUserName, $whichPass, $dbName);
    
    //build and execute the query to select patientID
    $patientSelectQuery = "select pmkPatientID from tblPatient where pmkPatientID = ?";
    $patientSelectParams = array($name);
    $patientSelectResults = $thisDatabaseReader->select($patientSelectQuery, $patientSelectParams, 1, 0, 0, 0, false, false);
    
    //extract the results and write them to a string for packaging to JSON
    $resultString = "";
    foreach($patientSelectResults as $val){
        $resultString = $resultString.$val[0];
    }
    echo json_encode(array('pmkPatientID' => $resultString));
  }
  //Otherwise, test if we are receiving a POST request
  elseif($_SERVER['REQUEST_METHOD']=="POST")
  {
    //extract the username and the age variable from the header
    $pmkPatientID = $_GET["pmkPatientID"];
    $fldSessNum = $_GET["fldSessNum"];
    $fldSessionCompliance = $_GET["fldSessionCompliance"];
    $fldIntensity1 = $_GET["fldIntensity1"];
    $fldIntensity2 = $_GET["fldIntensity2"];
    $fldStartTime = $_GET["fldStartTime"];
    $fldEndTime = $_GET["fldEndTime"];
    $fldNote = $_GET["fldNote"];
    $fldDeviceSynced = $_GET["fldDeviceSynced"];

    //convert fldSessNum to new format (with patientID prefix)
    $I=  substr($pmkPatientID, 0, -8);
    $fldSessNum=$I.$fldSessNum;

    //create the database writerObject
    $dbUserName = DB_WRITER;
    $whichPass = "w"; //flag for which one to use.
    $dbName = DATABASE_NAME;
    $thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);
    
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
    $deviceSynchedUpdateQuery= "Update tblPatient set fldDeviceSynced = ? where pmkPatientID= ?";
    $deviceSynchedUpdateParams = array($fldDeviceSynced,$pmkPatientID);
    $deviceSynchedUpdateResult = $thisDatabaseWriter->update($deviceSynchedUpdateQuery, $deviceSynchedUpdateParams, 1,0,0,0,false,false);
    
    header( 'HTTP/1.1 201: Resource Created' ); 
  }
  else{
    header('HTTP/1.1 501: NOT SUPPORTED');
  }
?>
