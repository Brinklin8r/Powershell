$session	= $null
$username 	= $env:USERNAME
$serverlist = 	'dc-app01.dc.bluepoint.com',
				'dc-app02.dc.bluepoint.com',
				'dc-app03.dc.bluepoint.com',
				'dc-app04.dc.bluepoint.com',
				'dc-app10.dc.bluepoint.com',
				'dc-app11.dc.bluepoint.com',
				'dc-mft01.dc.bluepoint.com',
				'dc-mft02.dc.bluepoint.com',
				'dc-mitek01.dc.bluepoint.com',
				'dc-mitek02.dc.bluepoint.com',
				'dc-mitek03.dc.bluepoint.com',
				'dc-mitek04.dc.bluepoint.com',
				'dc-dc01.dc.bluepoint.com',
				'dc-fs01.dc.bluepoint.com',
				'dc-mftg01.dc.bluepoint.com',
				'dc-mftg02.dc.bluepoint.com',
				'dc-web01.dc.bluepoint.com',
				'dc-web02.dc.bluepoint.com',
				'dc-web03.dc.bluepoint.com',
				'dc-web04.dc.bluepoint.com',
				'dc-web05.dc.bluepoint.com',
				'h-tst-app01.dc.bluepoint.com',
				'h-tst-app02.dc.bluepoint.com',
				'h-tst-app03.dc.bluepoint.com',
				'h-tst-app10.dc.bluepoint.com',
				'h-tst-app11.dc.bluepoint.com',
				'h-tst-mft01.dc.bluepoint.com',
				'h-tst-mft02.dc.bluepoint.com',
				'h-tst-mitek01.dc.bluepoint.com',
				'h-tst-mitek02.dc.bluepoint.com',
				'h-tst-mitek03.dc.bluepoint.com',
				'h-tst-mitek04.dc.bluepoint.com',
				'h-tst-db01.dc.bluepoint.com',
				'h-tst-fs01.dc.bluepoint.com',
				'h-tst-mftg01.dc.bluepoint.com',
				'h-tst-web01.dc.bluepoint.com',
				'h-tst-web02.dc.bluepoint.com',
				'h-tst-web03.dc.bluepoint.com',
				'h-tst-web04.dc.bluepoint.com',
				'h-tst-web05.dc.bluepoint.com'
				
foreach ($server in $serverlist){
	Write-Host "Checking server:" $server
	try {
		$QUResult = quser /server:$server 2>&1
#	http://rcmtech.wordpress.com/2014/04/08/powershell-finding-user-sessions-on-rdsh-servers/
	} catch {
		continue
	}
	$session = (($QUResult | ? { $_ -match $username }) -split ' +')[2]
	
	if ($session) {
		Write-Host "Logging" $username "off server:" $server
		logoff $session /server:$server
	}
}