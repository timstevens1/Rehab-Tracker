<?php

//##############################################################################
//
// This page lists your tables and fields within your database. if you click on
// a database name it will show you all the records for that table. 
// 
// 
// This file is only for class purposes and should never be publicly live
//##############################################################################
include "top.php";

print'<h2>Patient Overview</h2>';
// Begin output
print "<article><div id='box'>";
// Display all the records for a given table
if ($tblPatient != "") {
    print '<aside id="records">';
    $query = 'SHOW COLUMNS FROM ' . $tblPatient;
    $info = $thisDatabaseReader->select($query, "", 0, 0, 0, 0, false, false);
    $span = count($info);
    print "<table id ='table'>";
// print out the column headings, note i always use a 3 letter prefix
// and camel case like pmkCustomerId and fldFirstName
    print '<tr>';
    $columns = 0;
    foreach ($info as $field) {
        print '<td><b>';
        $camelCase = preg_split('/(?=[A-Z])/', substr($field[0], 3));
        foreach ($camelCase as $one) {
            print $one . " ";
        }
        print '</b></td>';
        $columns++;
    }
    print '</tr>';
//now print out each record
    $query = 'SELECT * FROM ' . $tblPatient;
    if ($_SESSION['fldAdmin'] != 1) {
        $query .= " WHERE fnkCLIN = '" . $_SESSION['DocID'] . "'";
        $info2 = $thisDatabaseReader->select($query, "", 1, 0, 2, 0, false, false);
    } else {
        $info2 = $thisDatabaseReader->select($query, "", 0, 0, 0, 0, false, false);
    }

    foreach ($info2 as $rec) {
        print '<tr>';
        for ($i = 0; $i < $columns; $i++) {
            print '<td>';
            if ($i == 3) { //$i=3 is fldPatientEmail --> format so is a clickable link
                print '<a href="mailto:' . $rec[$i] . '">' . $rec[$i] . '</a></td>';
            } elseif ($i == 8) { //$i=8 is fldWeekCompliance --> format so a % is displayed
                $percentage = $rec[$i] * 100;
                print $percentage . '% </td>';
            } else {
                print htmlentities($rec[$i], ENT_QUOTES) . '</td>';
            }
        }
        print '</tr>';
    }
// all done
    print '</table>';
    print '</aside>';
}
print '</div>';
//begin analysis script
print '<aside>';
//if tblPatient and tblSeesion are not null
if($tblPatient != "" && $tblSession!= ""){
	//get the current date
	$currentDate = date('Y-m-d');	
	//generate a date  prior and parse it into a form the database can recognize
	$priorDate = date_format(date_modify(date_create($currentDate), '-2 day'),'Y-m-d');
	//this query select pmkS from tblPatient
	$tblPatientQuery = 'SELECT pmkPatientID FROM tblPatient';
	//get the patient primary key array
	$patientPrimaries = $thisDatabaseReader -> select($tblPatientQuery, "", 0, 0, 0, 0, false, false);
	//for all patients in the table
	foreach($patientPrimaries as $patientPrimary){
		//parse the pmk
		$thisPMK =  $patientPrimary[0];
		//print the pmk (testing)
		//print '<p>Patient pmk: ' . $thisPMK . '</p>';
		//this query selects data we want to analyze about the selected patient from tblSession
		$tblSessionQuery = 'SELECT fldSessNum, fldSessionCompliance, fldNote, fldDeviceSynced FROM  tblSession  WHERE pmkPatientID = ? AND fldDeviceSynced BETWEEN ? AND ?';
		//encapsulate the data for security
		$sessionInfoData = array($thisPMK,$priorDate,$currentDate);
		//get the data from the table
		$sessionInformation = $thisDatabaseReader -> select($tblSessionQuery, $sessionInfoData, 1, 2, 0, 0, false, false);
		//if they have more than one session
		if(count($sessionInformation)>1){
			//print the number of sessions this patient has in the database (testing)
			//print '<p>Data from ' . count($sessionInformation) . ' sessions available</p>';
			//initialize an accumulator for session compliance
			$averageCompliance = 0;
			//for each individual session
			foreach($sessionInformation as $individualSession){
				//increment the accumulator by compliance from this session	
				$averageCompliance += $individualSession[1];
				//print out the session info (testing)
				//print '<p>Session Number: ' . $individualSession[0] . ' Sesion Compliance: ' .$individualSession[1] . ' Note: ' . $individualSession[2] . ' Sync Date: ' . $individualSession[3] . '</p>';
			}
			//print out average compliance
			//print '<p>Average compliance: ' . $averageCompliance/count($sessionInformation) . '</p>';
			//option to test average compliance
			if(($averageCompliance/count($sessionInformation))>0){
				//create the tblPush insertion query
				$insertionQuery = 'INSERT INTO tblPush SET fnkPatientID = ?, fnkMessageID = ?';
				//encapsulate the patient data
				$patientDataArray = array($thisPMK, rand(1,16));
				//here we will insert into tblPush
				$insertion = $thisDatabaseWriter -> insert($insertionQuery, $patientDataArray, 0, 0, 0, 0, false, false);
			}
		} else {
			//crate the tblPush insertion query for non compliance within two days
			$insertionQueryNonComp = 'INSERT INTO tblPush SET fnkPatientID = ?, fnkMessageID = ?';
			//encapsulate the patient data
			$patientDataNonCompArray = array($thisPMK, rand(17,18));
			//insert into tblPush
			$insertionNonComp = $thisDatabaseWriter -> insert($insertionQueryNonComp, $patientDataNonCompArray, 0, 0, 0, 0, false, false);	
		}		
	}
}
print '</aside>';
//end analysis script
print '</article>';
////--------------------TBLSESSION INFORMATION--------------------------------
//
//// Begin output
//
//print' <h2>Patient Sessions</h2>';
//print "<article><div id= 'box'>";
//
//// Display all the records for a given table
//if ($tblSession != "") {
//    print '<aside id="records">';
//    $query = 'SHOW COLUMNS FROM ' . $tblSession;verageCompliance = 0;

//    $info = $thisDatabaseReader->select($query, "", 0, 0, 0, 0, false, false);
//    $span = count($info);
////print out the table name and how many records there are
//    print "<table id='table'>";
//// print out the column headings, note i always use a 3 letter prefix
//// and camel case like pmkCustomerId and fldFirstName
//    print '<tr>';
//    $columns = 0;
//    foreach ($info as $field) {
//        print '<td><b>';
//        $camelCase = preg_split('/(?=[A-Z])/', substr($field[0], 3));
//        foreach ($camelCase as $one) {
//            print $one . " ";
//        }
//        print '</b></td>';
//        $columns++;
//    }
//    print '</tr>';
////now print out each record
//    $query = "SELECT * FROM ".  $tblSession;
//    $info3 = $thisDatabaseReader->select($query, "", 0, 0, 0, 0, false, false);
//    foreach ($info3 as $rec) {
//        print '<tr>';
//        for ($i = 0; $i < $columns; $i++) {
//            print '<td>' . $rec[$i] . '</td>';
//        }
//        print '</tr>';
//    }
//// all done
//    print '</table>';
//    print '</aside>';
//}
print '</div></article>';

include "footer.php";
?>
