Import-Module ActiveDirectory
$computers = Get-ADComputer -SearchBase 'OU=Production,DC=dc,DC=bluepoint,DC=com' -Filter 'ObjectClass -eq "Computer"' -Server dc.bluepoint.com

 ForEach ($computer in $computers) {
$client = $Computer.Name
if (Test-Connection -Computername $client -BufferSize 16 -Count 1 -Quiet) {
    Write-Host $client is online
    }
}