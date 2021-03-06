$objDomain = [adsi]'LDAP://dc=dc,dc=bluepoint,dc=Com'
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = "(&(objectCategory=computer)(name=DC-*))"
$objSearcher.PageSize = 1000
$colProplist = "*"
foreach ($i in $colPropList){
	$objSearcher.PropertiesToLoad.Add($i) | out-null
}
$colResults = $objSearcher.FindAll()
$serverlist = @()
foreach ($objResult in $colResults) {
	$serverlist += $objResult.Properties.dnshostname
}   # all Production Server
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = "(&(objectCategory=computer)(name=H-TST-*))"
$objSearcher.PageSize = 1000
foreach ($i in $colPropList){
	$objSearcher.PropertiesToLoad.Add($i) | out-null
}
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults) {
	$serverlist += $objResult.Properties.dnshostname
}   # all Staging Servers.

foreach ($server in $serverlist){
	Write-Host "`nSessions found on $server :" -ForegroundColor Red -BackgroundColor Yellow
	$ErrorActionPreference = "Continue"
	$QUResult = quser /server:$server 2>&1
	$ErrorActionPreference = "Stop"
	if($QUResult -notmatch "no user exists for") {
		if($QUResult -notmatch "Error") {
    		$QUResult
		}
	}
}