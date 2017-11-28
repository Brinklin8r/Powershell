################################################################################
#	Query IPHub for the number of Lifeboat release files (including Cascade in 
#    in the MAIN DataCenter) and compare that number with the number of files
#    FTP'd to Corporate One.
################################################################################

################################################################################
#	Variable Declarations
################################################################################
$DatabaseServer = "clus-sql2-BPS1.cloudworks.com"; 
$Uid = "bluepoint"; 
$Pwd = "sa_bps1"; 
#	SQL Connection Info 
$DBase = "check21"; 
#	Name of IPHub database



################################################################################
function QueryDBServer ( [string] $fQuery, [string] $fDatabase ) {
#	Returns a SQL DataSet containing the results from the supplied Querie

#	Connection Object
	$fSqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$fSqlConnection.ConnectionString = ConnectToDB $DatabaseServer $fDatabase $Uid $Pwd

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
function ConnectToDB ([string]$fDBServer,[string]$fDB,[string]$fUN,[string]$fPW) {
#	Create and return the conenction string to log into the supplied DB
	$fConnectString = "Server={0};" -f $fDBServer
	$fConnectString = $fConnectString + "Database={0};" -f $fDB
	$fConnectString = $fConnectString + "uid={0};" -f $fUN
	$fConnectString = $fConnectString + "pwd={0};" -f $fPW
	$fConnectString = $fConnectString + "Integrated Security=False"
	
	return $fConnectString
}
################################################################################
#	Main Program
################################################################################
$logingDate = Get-Date -Format "MMddyyyy"
$dt = Get-Date -Verbose
$logpath = "e:\bin\log" + $logingDate + ".txt"
"Starting IPHUBGOANYWHERE.PS1 {0}" -f $dt|Out-File $logpath -Append

################################################################################
#	Query IPHub for the number of Lifeboat release files (including Cascade in 
#    in the MAIN DataCenter) and compare that number with the number of files
#    FTP'd to Corporate One.
################################################################################
$QueryDBase = "
-- Procedure Start
declare @SearchDate datetime, @JobCount int, @ReleaseCount int
set @SearchDate = CONVERT (date, getdate());

-- GoAnywhere Succeded Job Count
SELECT @JobCount =  count (*) 
  FROM [GADDATA].[GADDATA].[dpa_job]
  where 
	proj_name like 'SFTP Transfer to Corporate One%'
	and submit_time between @SearchDate and (@SearchDate + 1)
	and status = 'S'
-- GoAnywhere Succeded Job Count
-- Lifeboat Release files
SELECT @ReleaseCount = count (*)
  FROM [IPHubLB].[dbo].[RDCReleasedFiles]
  where
	ReleasedDate between @SearchDate and (@SearchDate + 1)
	and DailySeqNo <> 0
-- Lifeboat Release files
-- Cascade Release files
SELECT @ReleaseCount += count(*)
  FROM [Check21].[dbo].[RDCReleasedFiles]
  where
	ReleasedDate between @SearchDate and (@SearchDate + 1)
	and ReleaserParamOrgNum = 210077
-- Cascade Release files

select @SearchDate as 'Date',@JobCount as 'Job Count', @ReleaseCount as 'Release Count'"
$ds = QueryDBServer $QueryDBase $DBase


if ($ds.Tables[0].Rows.count) {
	"{0} GAJobs: {1} HubRF: {2}" -f $ds.Tables[0].Rows[0][0], $ds.Tables[0].Rows[0][1], $ds.Tables[0].Rows[0][2]|Out-File $logpath -Append
}
if ($ds.Tables[0].Rows[0][1] -ne $ds.Tables[0].Rows[0][2] ) {
	"PROBLEM!"|Out-File $logpath -Append
}
"Finished"|Out-File $logpath -Append
