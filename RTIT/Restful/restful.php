<?php
/** \file
 \brief Code for updating device ID of a patient.
 
 This code updates the device ID of a patient for push notifications.
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/restful.php).
 \cond
 **/
    
  // example request: http://path/to/resource/Example?method=sayHello&name=World
  
  require_once(realpath('../constants.php'));
  require_once "Database.php";
  echo($_SERVER['REQUEST_METHOD']);
  if($_SERVER['REQUEST_METHOD']=="POST")
  {

	//extract the username and the age variable from the header
	$postedJson = file_get_contents('php://input');
	$data = json_decode($postedJson, TRUE);
	$UDID = $data['UDID'];
	$pmkPatientID = $data['pmkPatientID'];
//create the database 	$dbUserName = get_current_user() . '_writer';
	$dbUserName = DB_WRITER;
	$whichPass = "w"; //flag for which one to use.
	$dbName = DATABASE_NAME;
	$thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);
	//build and execute the query
	$query = "UPDATE tblPatient SET UDID=? WHERE pmkPatientID=?";

	$parameters = array($UDID, $pmkPatientID);
	$result = $thisDatabaseWriter->update($query, $parameters, 1,0,0,0,false,false);
	header( 'HTTP/1.1 201: Resource Created' );	
  }
  else{
	header('HTTP/1.1 501: NOT SUPPORTED');
  }
?>
