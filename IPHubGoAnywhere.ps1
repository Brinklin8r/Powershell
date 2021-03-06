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
$logpath = "c:\bin\log" + $logingDate + ".txt"
"Starting IPHUBGOANYWHERE.PS1 {0}" -f $dt|Out-File $logpath -Append

################################################################################
#	Query IPHub for the number of Lifeboat release files (including Cascade in 
#    in the MAIN DataCenter) and compare that number with the number of files
#    FTP'd to Corporate One.
################################################################################
$QueryDBase = "
-- Procedure Start
declare @SearchDate datetime
set @SearchDate = CONVERT (date, getdate());

-- GoAnywhere Succeded Job Count
SELECT substring(proj_name,34,100) as [CU], count (*) as [SentJobs]
  into #tempGJobs
  FROM [GASDATA].[GASDATA].[dpa_job]
  where 
	proj_name like 'SFTP Transfer to Corporate One%'
	and submit_time between @SearchDate and (@SearchDate + 1)
	and status = 'S'
  group by proj_name
-- GoAnywhere Succeded Job Count
-- Lifeboat Release files
SELECT OrgName, count (*) as [ReleaseCount]
  into #tempRFiles
  FROM [IPHubLB].[dbo].[RDCReleasedFiles],[IPHubLB].[dbo].[MerchantOrgMaster]
  where
    ReleaserParamOrgNum = MasterOrgNum and
	ReleasedDate between @SearchDate and (@SearchDate + 1)
	and DailySeqNo <> 0
  group by OrgName
-- Lifeboat Release files
union all
-- Main Release files
SELECT OrgName, count (*) as [ReleaseCount]
  FROM [Check21].[dbo].[RDCReleasedFiles],[Check21].[dbo].[MerchantOrgMaster]
  where
    ReleaserParamOrgNum = MasterOrgNum and
	ReleasedDate between @SearchDate and (@SearchDate + 1)
	and ReleaserParamOrgNum in ( 210077 )
  group by OrgName
-- Main Release files

-- Results where GoAnywhere Job count <> Hub Release File count
select CU,SentJobs,ReleaseCount 
from #tempGJobs
join #tempRFiles
on #tempRFiles.OrgName like CONCAT('%', substring(#tempGJobs.CU,0,8), '%')
where SentJobs <> ReleaseCount 

-- Clean Up Temp Tables
if object_id('tempdb..#tempGJobs') is not null
    drop table #tempGJobs
if object_id('tempdb..#tempRFiles') is not null
    drop table #tempRFiles"
$ds = QueryDBServer $QueryDBase $DBase


for($i=0;$i -lt $ds.Tables[0].Rows.Count;$i++) { 
	"FI: {0} GoAnyWhere Jobs: {1} Hub Release Files: {2}" -f $ds.Tables[0].Rows[$i][0], $ds.Tables[0].Rows[$i][1], $ds.Tables[0].Rows[$i][2]|Out-File $logpath -Append
}

if ($ds.Tables[0].Rows.Count) { 
    "PROBLEM!"|Out-File $logpath -Append
}
"Finished"|Out-File $logpath -Append
