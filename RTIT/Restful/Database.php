<?php
/** \file
 \brief Code for connecting to the database and providing functions.
 
 This code establishes the connection to the database and handles all interactions with the database.
 
 More description of the class is [here] (class_database.html).
 
 The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/RTIT/Restful/Database.php).
 
 **/
    
//$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$
//
// This class is designed to connect to your database and to handle all
// interactions with the database.
// 
// $dbUserName - username you wish to open the database with, generally here at 
//               uvm they are yourusername_reader, yourusername_writer, 
//               yourusername_admin
// $whichPass - techncially i can figure out which passwoard based on the naming
//              conventions of the first letter after the _ in the username. 
//              However passing the letter in is not that hard and you may not
//              always have a convienent naming convention.
//              
// $dbName - the name of the database that you want to access
// 
// This class is based on this article by Tony Marston        
// http://www.tonymarston.net/php-mysql/3-tier-architecture.html
// 
// 
// NOTE: The security in place is a good start but may or may not be all you need
// 
// 
// You will need to know how many where clauses, quotes, conditional expressions
// and html characters are in your query as the query must match what is expected
// as a mechinism to prevent sql injection. If a query does not work sent it 
// testquery method which will display the counts for you.
// 
// I have put a $debugMe variable in each method just in case you need it.
// ussually you can find your problem with testquery.
// 
// All values should be passed into the methods in the value array and not part
// of the query string itself
// 
//$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$#$

/// This class is designed to connect to your database and to handle all interactions with the database.
class Database {

    public $db;

    /** \brief The constructor function where a function is called to build the connection to the database
     \param $dbUserName Username you wish to open the database with
     \param $whichPass First letter after the underscore in the username
     \param $dbName The name of the database that you want to access
     */
    public function __construct($dbUserName, $whichPass, $dbName) {
        $this->db = null;
        $this->connect($dbUserName, $whichPass, $dbName);
    }

    /** \brief Connect to the database
     \param $dbUserName Username you wish to open the database with
     \param $whichPass First letter after the underscore in the username
     \param $dbName The name of the database that you want to access
     \return $this->db The connection to the database
     */
    private function connect($dbUserName, $whichPass, $dbName) {
        require(realpath(__DIR__.'/../pass.php'));

        $debugMe =false;

        switch ($whichPass) {
            case "a":
                $dbUserPass = $dbAdmin;
                break;
            case "r":
                $dbUserPass = $dbReader;
                break;
            case "w":
                $dbUserPass = $dbWriter;
                break;
        }

        $query = NULL;

        $dsn = 'mysql:host=Med65:65002;dbname=';

        if ($debugMe) {
            print "<p>Username: " . $dbUserName;
            print "<p>DSN: " . $dsn . $dbName;
            print "<p>PW: " . $whichPass;
        }

        try {
            if (!$this->db)
                $this->db = new PDO($dsn . $dbName, $dbUserName, $dbUserPass);
            if (!$this->db) {
                if ($debugMe)
                    echo '<p>A You are NOT connected to the database!</p>';
                return 0;
            } else {
                if ($debugMe)
                    echo '<p>A You are connected to the database!</p>';
                return $this->db;
            }
        } catch (PDOException $e) {
            $error_message = $e->getMessage();
            if ($debugMe)
                echo "<p>A An error occurred while connecting to the database: $error_message </p>";
        }
        return $this->db;
    }

    // #########################################################################
    // counts the number of conditional statements in the query
    // its tricky since OR is in ORDER as is AND is in LAND etc.
    // AND, &&	Logical AND
    // NOT, !	Negates value
    // ||, OR	Logical OR
    // XOR
    
    /** \brief Count the number of conditional statements in the query
     \param $query The query for database
     \return $conditions The number of conditional statements
     */
    private function countConditions($query) {
        $conditions = 0;
        $andCount = 0;
        $notCount = 0;
        $orCount = 0;
        $xorCount = 0;

        $andCount = substr_count(strtoupper($query), ' AND ');
        $andCount = $andCount + substr_count(strtoupper($query), ')AND');
        $andCount = $andCount + substr_count(strtoupper($query), '&&');

        $notCount = substr_count(strtoupper($query), ' NOT');
        $notCount = $notCount + substr_count(strtoupper($query), ')NOT');
        $notCount = $notCount + substr_count(strtoupper($query), '!');

        $orCount = substr_count(strtoupper($query), ' OR');
        $orCount = $orCount + substr_count(strtoupper($query), ')OR');
        $orCount = $orCount + substr_count(strtoupper($query), '||');

        $xorCount = substr_count(strtoupper($query), ' XOR');

        $conditions = $andCount + $notCount + $orCount + $xorCount;

        return $conditions;
    }

    // #########################################################################
    // counts the number of quotes, single and double  plus html entity 
    // equivalents found in your query.
    
    /** \brief Count the number of quotes, single, double, and html entity equivalents found in the query
     \param $query The query for database
     \return $quoteCount The total number of those strings mentioned above
     */
    private function countQuotes($query) {
        $quoteCount = 0;
        $singleCount = 0;
        $doubleCount = 0;
        $singleEntityCount = 0;
        $doubleEntityCount = 0;
        $HTMLentityCount = 0;

        $singleCount = substr_count(strtoupper($query), "'");
        $doubleCount = substr_count(strtoupper($query), '"');
        $singleEntityCount = substr_count(strtoupper($query), "#39");
        $doubleEntityCount = substr_count(strtoupper($query), "#34");
        $HTMLentityCount = substr_count(strtoupper($query), "&QUOT");

        $quoteCount = $singleCount + $doubleCount + $singleEntityCount + $doubleEntityCount + $HTMLentityCount;

        return $quoteCount;
    }

    // #########################################################################
    // counts the number of symbols, mostly < and > which would be convereted to 
    // html entites in the method sanitize query if we dont flag them.
    
    /** \brief Count the number of symbols, mostly < and > which would be convereted to html entites in the method sanitize query if we dont flag them
     \param $query The query for database
     \return $symbolCount The total number of symbols including < and >
     */
    private function countSymbols($query) {
        $symbolCount = 0;
        $ltCount = 0;
        $gtCount = 0;

        $ltCount = substr_count(strtoupper($query), '<');
        $gtCount = substr_count(strtoupper($query), '>');

        $symbolCount = $ltCount + $gtCount;

        return $symbolCount;
    }

    // #########################################################################
    // counts the number of where clauses in the query. a select in a select 
    // will often have two where clauses (one for each query)
    
    /** \brief Count the number of where clauses in the query
     \param $query The query for database
     \return $whereCount The total number of 'WHERE' appearing in the query
     */
    private function countWhere($query) {
        $whereCount = 0;

        $whereCount = substr_count(strtoupper($query), ' WHERE ');

        return $whereCount;
    }

    // #########################################################################
    // Performs a delete query and returns boolean true or false based on 
    // success of query.
    
    /** \brief Perform a delete query and returns boolean true or false based on success of query
     \param $query The query for database
     \param $values An array that holds the values for all the ? in $query
     \param $wheres The total number of WHERE statements in the query
     \param $conditions The number of conditional statements in the query
     \param $quotes The number of quotes in the query
     \param $symbols The number of symbols in the query
     \param $spacesAllowed A boolean value showing if spaces are allowed
     \param $semiColonAllowed A boolean value showing if semicolons are allowed
     \return $success A boolean value of the success of the delete query
     */
    public function delete($query, $values = "", $wheres = 1, $conditions = 0, $quotes = 0, $symbols = 0, $spacesAllowed = false, $semiColonAllowed = false) {
        $success = false;

        if ($wheres != $this->countWhere($query)) {
            return $success;
        }

        if ($conditions != $this->countConditions($query)) {
            return $success;
        }

        if ($quotes != $this->countQuotes($query)) {
            return $success;
        }

        if ($symbols != $this->countSymbols($query)) {
            return $success;
        }

        if ($quotes == 0 AND $symbols == 0) {
            $query = $this->sanitizeQuery($query, $spacesAllowed, $semiColonAllowed);
        }

        $statement = $this->db->prepare($query);

        if (is_array($values)) {
            $success = $statement->execute($values);
        } else {
            $success = $statement->execute();
        }

        $statement->closeCursor();

        return $success;
    }

    //############################################################################
    // Performs an insert query and returns boolean true or false based on success
    // of query.
    
    /** \brief Perform a insert query and returns boolean true or false based on success of query
     \param $query The query for database
     \param $values An array that holds the values for all the ? in $query
     \param $wheres The total number of WHERE statements in the query
     \param $conditions The number of conditional statements in the query
     \param $quotes The number of quotes in the query
     \param $symbols The number of symbols in the query
     \param $spacesAllowed A boolean value showing if spaces are allowed
     \param $semiColonAllowed A boolean value showing if semicolons are allowed
     \return $success A boolean value of the success of the insert query
     */
    public function insert($query, $values = "", $wheres = 0, $conditions = 0, $quotes = 0, $symbols = 0, $spacesAllowed = false, $semiColonAllowed = false) {
        $success = false;

        if ($wheres != $this->countWhere($query)) {
            return $success;
        }

        if ($conditions != $this->countConditions($query)) {
            return $success;
        }

        if ($quotes != $this->countQuotes($query)) {
            return $success;
        }

        if ($symbols != $this->countSymbols($query)) {
            return $success;
        }

        if ($quotes == 0 AND $symbols == 0) {
            $query = $this->sanitizeQuery($query, $spacesAllowed, $semiColonAllowed);
        }

        $statement = $this->db->prepare($query);

        if (is_array($values)) {
            $success = $statement->execute($values);
        } else {
            $success = $statement->execute();
        }

        $statement->closeCursor();

        return $success;
    }

    // #########################################################################
    // Used the get the value of the autonumber primary key on the last insert
    // sql statement you just performed
    
    /** \brief Return the autonumber primary key on the last insert statement you just performed
     \return $recordSet[0]["LAST_INSERT_ID()"] The ID on the last insert statement
     */
    public function lastInsert() {
        $query = "SELECT LAST_INSERT_ID()";

        $statement = $this->db->prepare($query);

        $statement->execute();

        $recordSet = $statement->fetchAll();

        $statement->closeCursor();

        if ($recordSet)
            return $recordSet[0]["LAST_INSERT_ID()"];

        return -1;
    }

    // #########################################################################
    // attempt to sanitize queries
    // An attempt to stop Hackers as they try to end statments with a semi colon
    // so I replace those the letter Q (could be anything) which allows the 
    // query to execute but it will fail returning nothing.
    // spaces in this conext refer to %20 and most likely will not be in your
    // query
    
    /** \brief Sanitize queries for security
     \param $query The query for database
     \param $spacesAllowed A boolean value showing if spaces are allowed
     \param $semiColonAllowed A boolean value showing if semicolons are allowed
     \return $query The result query
     */
    function sanitizeQuery($query, $spacesAllowed = false, $semiColonAllowed = false) {
        $replaceValue = "Q";

        if (!$semiColonAllowed) {
            $query = str_replace(';', $replaceValue, $query);
        }

        $query = htmlentities($query, ENT_QUOTES);

        $query = str_replace('%20', $replaceValue, $query);

        return $query;
    }

    // #########################################################################
    // Performs a select query and returns an associtative array
    // 
    // $query should be in the form:
    //       SELECT fieldNames FROM table WHERE field = ?
    //       
    // $values is an array that holds the values for all the ? in $query.
    // 
    // Hackers try to add more where clauses and conditions so this is an 
    // attempt to not let them.
    // 
    // $wheres is the total number of WHERE statements in the query. 
    // 
    // $conditions is how many AND, &&, OR, ||, NOT, !, XOR are in the $query 
    //
    // $quotes is how many quotes your query string has
    // 
    // $symbols is for < and > in your conditional expression 
    // 
    // all of the above can be inside the wuery any place.
    //
    // function returns "" if it is not correct
    //
    // $this->sanitizeQuery is another attempt to stop Hackers
    //
    //  $spacesAllowed are %20 and not a blank space
    //  $semiColonAllowed is ; and generally you do not have them in your query
    //
    
    /** \brief Perform a select query and returns an associtative array
     \param $query The query for database
     \param $values An array that holds the values for all the ? in $query
     \param $wheres The total number of WHERE statements in the query
     \param $conditions The number of conditional statements in the query
     \param $quotes The number of quotes in the query
     \param $symbols The number of symbols in the query
     \param $spacesAllowed A boolean value showing if spaces are allowed
     \param $semiColonAllowed A boolean value showing if semicolons are allowed
     \return $recordSet The result generated from the select query
     */
    public function select($query, $values = "", $wheres = 1, $conditions = 0, $quotes = 0, $symbols = 0, $spacesAllowed = false, $semiColonAllowed = false) {

        if ($wheres != $this->countWhere($query)) {
            return "1";
        }

        if ($conditions != $this->countConditions($query)) {
            return "2";
        }

        if ($quotes != $this->countQuotes($query)) {
            return "3";
        }

        if ($symbols != $this->countSymbols($query)) {
            return "4";
        }

        if ($quotes == 0 AND $symbols == 0) {
            $query = $this->sanitizeQuery($query, $spacesAllowed, $semiColonAllowed);
        }

        $statement = $this->db->prepare($query);

        if (is_array($values)) {
            $statement->execute($values);
        } else {
            $statement->execute();
        }

        $recordSet = $statement->fetchAll();

        $statement->closeCursor();

        return $recordSet;
    }

    // #########################################################################
    /** \brief Test a query for the printed messages
     \param $query The query for database
     \param $values An array that holds the values for all the ? in $query
     \param $wheres The total number of WHERE statements in the query
     \param $conditions The number of conditional statements in the query
     \param $quotes The number of quotes in the query
     \param $symbols The number of symbols in the query
     \param $spacesAllowed A boolean value showing if spaces are allowed
     \param $semiColonAllowed A boolean value showing if semicolons are allowed
     */
    public function testquery($query, $values = "", $wheres = 0, $conditions = 0, $quotes = 0, $symbols = 0, $spacesAllowed = false, $semiColonAllowed = false) {

        print "<p>TEST Query: does not execute.</p>";

        print "<p>WHERE: " . $wheres . " = " . $this->countWhere($query) . "</p>";
        if ($wheres != $this->countWhere($query)) {
            print "<p class='noticeMe'>Failed where count.</p>";
        }

        print "<p>CONDITIONS: " . $conditions . " = " . $this->countConditions($query) . "</p>";
        if ($conditions != $this->countConditions($query)) {
            print "<p class='noticeMe'>Failed conditions count.</p>";
        }

        print "<p>QUOTES: " . $quotes . " = " . $this->countQuotes($query) . "</p>";
        if ($quotes != $this->countQuotes($query)) {
            print "<p class='noticeMe'>Failed quote count.</p>";
        }

        print "<p>SYMBOLS: " . $symbols . " = " . $this->countSymbols($query) . "</p>";
        if ($symbols != $this->countSymbols($query)) {
            print "<p class='noticeMe'>Failed symbol count.</p>";
        }

        if ($quotes == 0 AND $symbols == 0) {

            $query = $this->sanitizeQuery($query, $spacesAllowed, $semiColonAllowed);
            print "<p>Santized Query: " . $query . "</p>";
        }

        print "<p>SQL Database.php->test: " . $query . "</p>";
        print "<p>values:<pre> ";
        print_r($values);
        print "</pre></p>";

        if (is_array($values)) {
            print "<p>Execute with values.</p>";
        } else {
            print "<p>Execute without values.</p>";
        }

        return "";
    }

    // #########################################################################
    // Performs an update query and returns boolean true or false based on 
    // success of query.
    
    /** \brief Perform an update query and returns boolean true or false based on success of query.
     \param $query The query for database
     \param $values An array that holds the values for all the ? in $query
     \param $wheres The total number of WHERE statements in the query
     \param $conditions The number of conditional statements in the query
     \param $quotes The number of quotes in the query
     \param $symbols The number of symbols in the query
     \param $spacesAllowed A boolean value showing if spaces are allowed
     \param $semiColonAllowed A boolean value showing if semicolons are allowed
     \return $success A boolean value of the success of the update query
     */
    public function update($query, $values = "", $wheres = 1, $conditions = 0, $quotes = 0, $symbols = 0, $spacesAllowed = false, $semiColonAllowed = false) {
        $success = false;

        if ($wheres != $this->countWhere($query)) {
            return $success;
        }

        if ($conditions != $this->countConditions($query)) {
            return $success;
        }

        if ($quotes != $this->countQuotes($query)) {
            return $success;
        }

        if ($symbols != $this->countSymbols($query)) {
            return $success;
        }

        if ($quotes == 0 AND $symbols == 0) {
            $query = $this->sanitizeQuery($query, $spacesAllowed, $semiColonAllowed);
        }

        $statement = $this->db->prepare($query);

        if (is_array($values)) {
            $success = $statement->execute($values);
        } else {
            $success = $statement->execute();
        }

        $statement->closeCursor();

        return $success;
    }

}

// end class
?>
