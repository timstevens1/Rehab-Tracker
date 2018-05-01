<?php
include "top.php";
?>
<?php

//--------------------Table displays summary of patients OUT of weekly compliance----------------
print "<article><h2>Patients who are OUT of compliance: </h2>";

$tableName = tblPatient;

$checkCompQuery = "SELECT pmkPatientID, fldWeekCompliance, fldPhone, fldPatientEmail FROM tblPatient ";
$complianceColumn = $thisDatabaseReader->select($checkCompQuery, "", 0, 0, 0, 0, false, false);

if ($tableName != "") {
    print '<aside id="records">';
    print '<table id = "table">';
    print '<tr>';
    $columns = 0;
    print'<th><b>Patient ID:</b></th>';
    print'<th><b>Compliance:</b></th>';
    print '<th><b>Week Start:</b></th>';
    print '<th><b>Device Synced:</b></th>';
//    foreach ($complianceColumn as $field) {
//        $columns++;
//    }
    $columns = 4;
    print '</tr>';
}
print '</article>';
////now print out each record
$notCompliant = "SELECT pmkPatientID, fldWeekCompliance, fldWeekStart, fldDeviceSynced FROM " 
        . $tableName . " WHERE fldWeekCompliance < 1 and fnkCLIN = '" . $_SESSION['DocID'] . "'"
        . " ORDER BY fldWeekCompliance ";
$complianceResult = $thisDatabaseReader->select($notCompliant, "", 1, 2, 2, 1, false, false);
foreach ($complianceResult as $rec) {
    print '<tr>';
    for ($i = 0; $i < $columns; $i++) {
            print '<td>' . $rec[$i] . '</td>';
    }
    print '</tr>';
}
print '</table>';

// all done

print '</aside>';
?>

<!-- ------ TABLE LISTS ALL PATIENTS FOR LOGGED IN CLINICIAN------------------------ -->

<article><div id='box'>
<!--        <p>*This is a glance at the patients who are out of compliance. </p>
        <p>  More information can be found on the Patient Overview or Patient Sessions pages. </p></br>-->
        <h2>Summary of Active Patients for Clinician <?php print $_SESSION['DocID']; ?> </h2>


<?php
//Display all the records for a given table
if ($tblPatient != "") {


    print '<aside id="records">';
//    $query = 'SHOW COLUMNS FROM ' . $tblPatient;
//    
    print "<table id ='table'>";
// print out the column headings, note i always use a 3 letter prefix
// and camel case like pmkCustomerId and fldFirstName
    print '<tr>';
    $columns = 0;
    $overviewDisplay = array('Pateint ID', 'Clinician', 'Device Synced', 'Start Date', 'Compliance Checked', 'Week Compliance', 'Goal','Week Start');
    foreach ($overviewDisplay as $field) {
        print '<td><b>';
        print $field;
        print '</b></td>';
        $columns++;
    }
    print '</tr>';
//now print out each record
    $patientSummary = 'SELECT pmkPatientID, fnkCLIN, fldDeviceSynced, fldStartDate, fldComplianceChecked, fldWeekCompliance, fldGoal, fldWeekStart' 
            . " FROM $tblPatient WHERE fnkCLIN = '" . $_SESSION['DocID'] . "'";
    
    $displaySummary = $thisDatabaseReader->select($patientSummary, "", 1, 0, 2, 0, false, false);
    foreach ($displaySummary as $rec) {
        print '<tr>';
        for ($i = 0; $i < $columns; $i++) {
            print '<td>';
                print htmlentities($rec[$i], ENT_QUOTES) . '</td>';
        }
        print '</tr>';
    }
// all done
    print '</table>';
    print '</aside>';
}




print '</div></article>';

include "footer.php";
?>
