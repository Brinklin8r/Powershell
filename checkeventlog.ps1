Clear-Host

$Servers = "dc-mitek01.dc.bluepoint.com", "dc-mitek02.dc.bluepoint.com", "dc-mitek03.dc.bluepoint.com", "dc-mitek04.dc.bluepoint.com"

$addDays = 0

foreach ($server in $Servers) {

    Write-Host -foregroundcolor Red $server
	get-eventlog -ComputerName $server -log system | where {$_.eventID -eq 1014} | Format-List
    
}