$objDomain = [adsi]'LDAP://dc=dc,dc=bluepoint,dc=Com'
#$objDomain = [adsi]'LDAP://dc=bluepoint,dc=Com'
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = "(&(objectCategory=computer)(name=DC-*))"
#$objSearcher.Filter = "(&(objectCategory=computer)(name=*))"
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

$NameRegex = '*Management Studio*'

foreach ($comp in $serverlist) {
    $keys = '','\Wow6432Node'
    foreach ($key in $keys) {
        try {
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $comp)
            $apps = $reg.OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall").GetSubKeyNames()
        } catch {
            continue
        }

        foreach ($app in $apps) {
            $program = $reg.OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app")
            $name = $program.GetValue('DisplayName')
            if ($name -and $name -like $NameRegex) {
                [pscustomobject]@{
                    ComputerName = $comp
                    DisplayName = $name
                }
            }
        }
    }
}