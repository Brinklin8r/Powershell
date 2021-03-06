################################################################################
#	Query IPHub for the number of Lifeboat release files (including Cascade in 
#    in the MAIN DataCenter) and compare that number with the number of files
#    FTP'd to Corporate One.
################################################################################

################################################################################
#	Variable Declarations
################################################################################
$DatabaseServer = "DC-SQL01.dc.bluepoint.com"; 

$DBaseGA = "GASDATA"; 
#	Name of GoAnywhere database
$DBaseIPH = "Check21"; 
#	Name of IPHub database
$DBaseLB = "IPHubLB"; 
#	Name of Lifeboat database

$DBServer = "clus-sql2-BPS1.cloudworks.com";
$DBUN = "bluepoint";
$DBPW = "sa_bps1";

################################################################################
function QueryDBServer ( [string] $fQuery, [string] $fDBConStr) {
#	Returns a SQL DataSet containing the results from the supplied Querie

#	Connection Object
	$fSqlConnection = New-Object System.Data.SqlClient.SqlConnection
#    $fSqlConnection.ConnectionString = ConnectToDB $DatabaseServer $fDatabase $Uid $Pwd
    $fSqlConnection.ConnectionString =  $fDBConStr

#	Data Adapter which will gather the data using our query
	$fda = New-Object System.Data.SqlClient.SqlDataAdapter($fQuery, $fSqlConnection)

#	DataSet which will hold the data we have gathered
	$fds = New-Object System.Data.DataSet

#	Out-Null is used so the number of affected rows isn't printed
	$fda.Fill($fds) | Out-Null
#	Close the database connection
	$fSQLConnection.Close()

	return $fds
}
################################################################################
function ConnectToDBSQL ([string]$fDBServer, [string]$fDB, [string]$fUN, [string]$fPW) {
    # Create and return the conenction string to log into the supplied DB using
    # SQL Authentication
        $fConnectString = "Server={0};" -f $fDBServer
        $fConnectString = $fConnectString + "Database={0};" -f $fDB
        $fConnectString = $fConnectString + "uid={0};" -f $fUN
        $fConnectString = $fConnectString + "pwd={0};" -f $fPW
        $fConnectString = $fConnectString + "Integrated Security=False"
        
        return $fConnectString
    }
################################################################################
function ConnectToDB ([string]$fDBServer, [string]$fDB) {
    # Create and return the conenction string to log into the supplied DB using
    # Domain Authentication
        $fConnectString = "Server={0};" -f $fDBServer
        $fConnectString = $fConnectString + "Database={0};" -f $fDB
        $fConnectString = $fConnectString + "Integrated Security=TRUE"

        return $fConnectString
    }
################################################################################
#	Main Program
################################################################################
$logingDate = Get-Date -Format "MMddyyyy"
$dt = Get-Date -Verbose
$logpath = "c:\bin\log" + $logingDate + ".txt"
"Starting IPHUBGOANYWHERE.PS1 {0}" -f $dt|Out-File $logpath -Append

################################################################################
#	Query IPHub for the number of Lifeboat release files (including Cascade in 
#    in the MAIN DataCenter) and compare that number with the number of files
#    FTP'd to Corporate One.
################################################################################
$QueryGA = "
-- Procedure Start
declare @SearchDate datetime
set @SearchDate = CONVERT (date, getdate());
--set @SearchDate = CONVERT (date, '2017-07-27');

-- GoAnywhere Succeded Job Count
SELECT substring(proj_name,34,20) as [CU], count (*) as [SentJobs]
  FROM [GASDATA].[GASDATA].[dpa_job]
  where 
	proj_name like 'SFTP Transfer to Corporate One%'
	and submit_time between @SearchDate and (@SearchDate + 1)
	and status = 'S'
  group by proj_name
-- GoAnywhere Succeded Job Count"

$QueryLB = "
-- Procedure Start
declare @SearchDate datetime
set @SearchDate = CONVERT (date, getdate());
--set @SearchDate = CONVERT (date, '2017-07-27');

-- Lifeboat Release files
SELECT OrgName, count (*) as [ReleaseCount]
  FROM [IPHubLB].[dbo].[RDCReleasedFiles],[IPHubLB].[dbo].[MerchantOrgMaster]
  where
    ReleaserParamOrgNum = MasterOrgNum and
	ReleasedDate between @SearchDate and (@SearchDate + 1)
	and DailySeqNo <> 0
  group by OrgName
-- Lifeboat Release files"

$QueryIPH = "
-- Procedure Start
declare @SearchDate datetime
set @SearchDate = CONVERT (date, getdate());
--set @SearchDate = CONVERT (date, '2017-07-27');

SELECT OrgName, count (*) as [ReleaseCount]
FROM [Check21].[dbo].[RDCReleasedFiles],[Check21].[dbo].[MerchantOrgMaster]
where
    ReleaserParamOrgNum = MasterOrgNum and
	ReleasedDate between @SearchDate and (@SearchDate + 1)
	and TotalItems > 0
	and ReleaserParamOrgNum in ( 210077,  -- Cascade FCU
								 461385,  -- Pasadena Federal CU
								 471268 ) -- Northwest Preferred FCU
group by OrgName
-- Main Release files"


$conStr = ConnectToDB $DatabaseServer $DBaseGA
$dsGA = QueryDBServer $QueryGA $conStr

#"GoAnywhere FIs: {0} {1}" -f $dsGA.Tables[0].Rows.Count,$conStr|Out-File $logpath -Append

$conStr = ConnectToDB $DatabaseServer $DBaseLB
$dsLB = QueryDBServer $QueryLB $conStr

#"Lifeboat FIs: {0} {1}" -f $dsLB.Tables[0].Rows.Count,$conStr|Out-File $logpath -Append

#$conStr = ConnectToDBSQL $DBServer $DBaseIPH $DBUN $DBPW
$conStr = ConnectToDB $DatabaseServer $DBaseIPH
$dsIPH = QueryDBServer $QueryIPH $conStr

#"Main FIs: {0} {1}" -f $dsIPH.Tables[0].Rows.Count,$conStr|Out-File $logpath -Append

# Add Main results to Lifeboat Results
foreach ($dr in $dsIPH.Tables[0]) {
    $dsLB.Tables[0].Rows.Add($dr.ItemArray) | Out-Null
}

#"New Lifeboat FIs: {0}" -f $dsLB.Tables[0].Rows.Count|Out-File $logpath -Append

#for($i=0;$i -lt $dsLB.Tables[0].Rows.Count;$i++) { 
#	"FI: {0} Hub Release Files: {1}" -f $dsLB.Tables[0].Rows[$i][0], $dsLB.Tables[0].Rows[$i][1]|Out-File $logpath -Append
#}


foreach ($drGA in $dsGA.Tables[0]) {
    $tempCounter = 0
    foreach ($drLB in $dsLB.Tables[0]) {
        if (! ($drGA[0].Substring(0,6).CompareTo($drLB[0].Substring(0,6)))) {
            $prob = " <- PROBLEM!"
            if($drGA[1] -eq $drLB[1] ){
                $prob = ""
            }
            "FI: {0,15} Hub Release Files: {2,2} GoAnyWhere Jobs: {1,2} {3}" -f 
                $drGA[0], 
                $drGA[1], 
                $drLB[1],
                $prob |Out-File $logpath -Append
            $tempCounter++
       }
    }
# Incase some how there are GoAnwhere Jobs and No Hub Release files
    if ($tempCounter -eq 0) {
        "FI: {0,15} GoAnyWhere Jobs: {1} Hub Release Files: 0 <- PROBLEM!" -f 
            $drGA[0], 
            $drGA[1]|Out-File $logpath -Append 
    }
}

"Finished"|Out-File $logpath -Append
