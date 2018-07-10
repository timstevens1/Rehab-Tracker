<?php
/** \file
 \brief Code for retrieving a patient's target intensity or inserting a new session.
 
 This code retrieves a patient's target intensity for a GET request or inserts a session of the patient for a POST request.
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/getTatgetIntensity.php).
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
	
	//build our query
	$query = "select fldGoal from tblPatient where pmkPatientID = ?";
	$parameters = array($name);
	//execute the query on the database object
	$results = $thisDatabaseReader->select($query, $parameters, 1, 0, 0, 0, false, false);
        
	
	//extract the results and write them to a string for packaging to JSON
	$resultString = "";
	foreach($results as $val){
		$resultString = $resultString.$val[0];
	}
	echo json_encode(array('fldGoal' => $resultString));
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
        $fldDate = $_GET["fldDate"];
        $fldNote = $_GET["fldNote"];
        $fldLastUpdate = $_GET["fldLastUpdate"];
	//create the database writerObject
	$dbUserName = DB_WRITER;
	$whichPass = "w"; //flag for which one to use.
	$dbName = DATABASE_NAME;
	$thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);
	
        $I=  substr($pmkPatientID, 0, -8);
        $fldSessNum=$I.$fldSessNum;
	//build and execute the query
	$query = "INSERT INTO tblSession(pmkPatientID, fldSessNum, fldSessionCompliance, fldIntensity1, fldIntensity2, fldDate, fldNote) VALUES (?, ?, ?, ?, ?, ?, ?)";
	$parameters = array($pmkPatientID, $fldSessNum, $fldSessionCompliance, $fldIntensity1, $fldIntensity2, $fldDate, $fldNote);
	$result = $thisDatabaseWriter->insert($query, $parameters, 0,0,0,0,false,false);
        
        $query2= "Update tblPatient set fldLastUpdate = ? where pmkPatientID= ?";
        $parameters2 = array($fldLastUpdate,$pmkPatientID);
        $result = $thisDatabaseWriter->update($query2, $parameters2, 1,0,0,0,false,false);
	
	header( 'HTTP/1.1 201: Resource Created' );	
  }
  else{
	header('HTTP/1.1 501: NOT SUPPORTED');
  }
?>
