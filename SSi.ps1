#$objDomain = [adsi]'LDAP://dc=dc,dc=bluepoint,dc=Com'
#$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
#$objSearcher.SearchRoot = $objDomain
#$objSearcher.Filter = "(&(objectCategory=computer)(name=DC-*))"
#$objSearcher.PageSize = 1000
#$colProplist = "*"
#foreach ($i in $colPropList){
#	$objSearcher.PropertiesToLoad.Add($i) | out-null
#}
#$colResults = $objSearcher.FindAll()
#$serverlist = @()
#foreach ($objResult in $colResults) {
#	$serverlist += $objResult.Properties.dnshostname
#}   # all Production Server

$serverlist = @"DC-App01.dc.bluepoint.com"

ForEach ($System in $serverlist){
    #Pings machine's found in text file
    if (!(test-Connection -ComputerName $System -BufferSize 16 -Count 1 -ea 0 -Quiet))
    {
        Write-Host "$System Offline"
    }
    Else
    {
     #Providing the machine is reachable 
     #Checks installed programs for products that contain Kaspersky in the name
     Try {Get-WMIObject -Class win32_product -Filter {Name = "SQL Server Management Studio"}
       -ComputerName $System -ErrorAction STOP | 
          Select-Object -Property $System,Name,Version }
     Catch {#If an error, do this instead
            Write-Host "$system Offline "}
     #EndofElse
     }
#EndofForEach
}


