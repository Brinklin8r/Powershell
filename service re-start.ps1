$authUN = 'tam5\tam'
$authPW = 'tam'

$serverName = 'TAM5'
$serviceName = 'BP License Comm'

$secpasswd = ConvertTo-SecureString $authPW -AsPlainText -Force
$CredObj = New-Object System.Management.Automation.PSCredential($authUN, $secpasswd)

(gwmi -computername $serverName -class win32_service -credential $CredObj | Where-Object { $_.Name -eq $serviceName }).stopservice()
Start-Sleep -s 60

(gwmi -computername $serverName -class win32_service -credential $CredObj | Where-Object { $_.Name -eq $serviceName }).startservice()
Start-Sleep -s 60