<<?php
/** \file
 \brief Code for checking patient's compliance everyday.
 
 This code checks patient's compliance since the first day of a week and selects a corresponding message.
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/cronDatabaseCompliance.php).
 \cond
 **/
//begin analysis script
	require_once realpath(dirname(dirname(__FILE__))."\constants.php");
	require_once "Database.php";
	date_default_timezone_set('EST');
	$dbUserName = DB_WRITER;
	$whichPass = "w"; //flag for which one to use.
	$dbName = DATABASE_NAME;
	$RTC = true;
	$thisDatabaseWriter = new Database($dbUserName, $whichPass, $dbName);
	//get the current date
	$currentDate = date('Y-m-d');
	//this query select pmkS from tblPatient
	$tblPatientQuery = 'SELECT pmkPatientID, fldWeekStart, DAYOFWEEK(fldWeekStart), fldWeekCompliance FROM tblPatient';
	//get the patient primary key array
	$patientPrimaries = $thisDatabaseWriter -> select($tblPatientQuery, "", 0, 0, 0, 0, false, false);

	foreach($patientPrimaries as $patientPrimary){
		//parse the pmk

		$thisPMK =  $patientPrimary[0];
		$weekStart = $patientPrimary[1];
		$dayCount = (strtotime($currentDate) - strtotime($weekStart))/86400;
		if($dayCount== 3 and $patientPrimary[3]==0){
			$insertionQuery = 'INSERT INTO tblPush (fnkPatientID, fnkMessageID, fldDelivered) VALUES(?,43,0)';
				//encapsulate the patient data
			$patientDataArray = array( $thisPMK);
				//here we will insert into tblPush
			$insertion = $thisDatabaseWriter -> insert($insertionQuery, $patientDataArray, 0, 0, 0, 0, false, false);
		}
		if($dayCount == 7){
			$tblSessionQuery = 'SELECT fldSessNum, fldStartTime FROM  tblSession  WHERE pmkPatientID = ? AND fldDeviceSynced BETWEEN ? AND ?';
		//encapsulate the data for security
			$sessionInfoData = array($thisPMK,$weekStart,$currentDate);
		//get the data from the table
			$sessionInformation = $thisDatabaseWriter -> select($tblSessionQuery, $sessionInfoData, 1, 2, 0, 0, false, false);
		
		// create an array with 1 element per day of the last week
			$sessionDays = array(0);
			$sessionDays = array_pad($sessionDays,$dayCount + 1, 0);
			foreach($sessionInformation as $session){
				$dayNum = (strtotime($session[1]) - strtotime($weekStart))/86400;
				$sessionDays[$dayNum] = 1;
			}
			$SessionCount = array_sum($sessionDays);
			if($RTC){
				$SesionCount = $patientPrimary[3];
			}
			if($SessionCount >= 5){
				$messageIndex = rand(22,33);
			}
			elseif($SessionCount == 4) {
				$messageIndex = rand(39,42);
			}
			elseif ($SessionCount == 3) {
				$messageIndex = rand(38,41);
			}
			else{
				$messageIndex = rand(34,37);
			}
			$insertionQuery = 'INSERT INTO tblPush (fnkPatientID, fnkMessageID, fldDelivered) VALUES(?,?,?)';
				//encapsulate the patient data
			$patientDataArray = array( $thisPMK, $messageIndex,0);
				//here we will insert into tblPush
			$insertion = $thisDatabaseWriter -> insert($insertionQuery, $patientDataArray, 0, 0, 0, 0, false, false);


			$tblPatientQuery = 'UPDATE tblPatient SET fldComplianceChecked=CAST(CURRENT_TIMESTAMP as DATE), fldWeekCompliance=?,fldWeekStart=? WHERE pmkPatientID=?';

			$weekStart = $currentDate;
			$success = $thisDatabaseWriter->update($tblPatientQuery,array(0,$weekStart, $thisPMK),1,0,0,0,false,false);
		}

		elseif ($dayCount > 7) {
			$dateMod = date('w') - date('w',strtotime($weekStart));
			if($dateMod < 0){
				$dateMod  = $dateMod + 7;
			}
			$weekStart = date_format(date_modify(date_create($currentDate), '-'.$dateMod.'day'),'Y-m-d');
			$success = $thisDatabaseWriter->update('UPDATE tblPatient SET fldWeekStart=? WHERE pmkPatientID=?',array($weekStart, $thisPMK),1,0,0,0,false,false);
		}
	}
	$success = $thisDatabaseWriter->update('UPDATE tblPush SET fldDelivered = 0 WHERE fldDelivered IS NULL',"",1,0,0,0,false,false);
//end analysis script
?>
