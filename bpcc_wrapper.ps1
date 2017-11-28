##define variables
$members #array
$db_server #string
$db_name  #string
$db_user #string
$db_pass #string
$conn #string
$query = "select distinct(mxmemnum) from members where rectype = 'memb'"
$bpcc_path #string


##define program

##step 1 - query db for members
	#get db name, user, and pass
	$db_server = Read-Host "DB Server: "
	$db_name = Read-Host "DB Name: "
	$db_user = Read-Host "DB User: "
	$db_pass = Read-Host "DB Pass: "
	$bpcc_path = Read-Host "Full path to Bluepoint.ContainerCombiner.exe: "
	$outFile = $bpcc_path+"bpcc_wrapper.txt"
	#use data to build conn string
	$conn = New-Object System.Data.SqlClient.SqlConnection
	$conn.connectionString = "Server="+$db_server+";Database="+$db_name+";User Id="+$db_user+";Password="+$db_pass+";"
	#connect to db
	$conn.open()
	#execute query
	$adapter = New-Object System.Data.SqlClient.SqlDataAdapter ($query, $conn)
	$table = New-Object system.Data.DataTable
	$adapter.fill($table) | Out-Null
	#write each member number to the array
	$members  = @($table | select -ExpandProperty mxmemnum)
	#close connection
	$conn.close()
##step 2 - execute bp container combiner for each member
	#get location of exe
	$bpcc_path += "Bluepoint.ContainerCombiner.exe"
	#launch cmd prompt
	#set directory path for exe
	#execute exe for one value in array
	#restart dart services
	#execute next value in array, repeat until all members done
	$count = $members.Length
	$i = 0
	while ($count -gt $i)
	{
		if ($members[$i] -gt 0 )
		{
			$bpcc_cmd = $bpcc_path+" /Members="+$members[$i]+" /parallel"
			Invoke-Expression $bpcc_cmd | Out-File $outFile -Append
			Restart-Service BPDartService | Out-File $outFile -Append
			Start-Sleep 10 | Out-File $outFile -Append
			$i++
		}
	}