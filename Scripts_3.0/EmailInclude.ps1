################################################################################
#
# Email Function Include:
#	These are some base email function that is reused.
#	I created this to be included into other programs.#
#
# Coded By:
#	Chris Brinkley
#
# Version:
#	1.0.0 	- 04/16/2013 -	Initial Build.
#
################################################################################

################################################################################
# Variable Declarations
################################################################################

################################################################################
# Function Declarations
################################################################################

function CreateEmailXML ([XML]$fxml, [string]$mailCase, [string]$msgBody ){
	$fxml.eMail.User |  Where-Object { $_.UN -ne '' } | ForEach-Object { 
		$authUN = $_.UN } |Out-Null
	$fxml.eMail.User |  Where-Object { $_.PW -ne '' } | ForEach-Object { 
		$authPW = $_.PW } |Out-Null
	
	$fxml.eMail.ServerInfo |  Where-Object { $_.name -eq $mailCase 
		} | ForEach-Object { 
			$mailServer = $_.mailServer
			$msgFrom = $_.mailFrom
			$msgTo = $_.mailTo
			$msgSub = $_.mailSub 
		} |Out-Null

	$msg = new-object Net.Mail.MailMessage
#		Creates email message object
	
	$smtp = New-Object Net.Mail.SmtpClient($mailServer)
#		Creates new SMTP connection object

	$smtp.EnableSsl = $true 
#	$smtp.UseDefaultCredentials = $true
#		Use Executing User's credential
	$smtp.Credentials = New-Object System.Net.NetworkCredential($authUN, $authPW);  
#		Use different credentials that the executing user
	$msg.From = $msgFrom
	if ( $testing ){
		$msgTo = "Chris.Brinkley@bluepointsolutions.com"
		$msgSub = "Testing - " + $msgSub
	} else{
		$msg.To.Add("IT@bluepointsolutions.com")
		$msg.To.Add("Escalations@bluepointsolutions.com")
			
	}
	$msg.To.Add($msgTo)
	$msg.Subject = $msgSub
	$msg.IsBodyHTML = $true
#		Send mail as HTML
	$msg.Body = $msgBody
	$smtp.Send($msg)
	Write-Host "Email Sent"
#		Used for testing
}
################################################################################

function AddErrorToString ([xml]$fxml, [string]$outBody){
#	Takes in an XML object and makes a String.

	$fxml.SettingXMLFile.Error |  Where-Object { $_.eValue -ne '' 
		} | ForEach-Object {$outBody = $outBody + $_.eValue + "<br>" } |Out-Null
	$outBody = $outBody + "Last e-mail sent:  "
	$fxml.SettingXMLFile.Setting |  Where-Object { $_.name -eq 'LastEmail'
		} | ForEach-Object { $outBody = $outBody + $_.value + "<br>" } |Out-Null
	$outBody
}
################################################################################

function CreateEMAILBody ([xml]$fxml, [string]$btype){
#	Creates the email Body depending on the email "type"	
	
	switch ( $btype ) {
		'CarLar Error'	{ 
			$outBody = "New errors since last email:<br><br>" 
			$outBody = AddErrorToString $fxml $outBody
		}
		'No CarLar'		{ 
			$outBody = "The monitoring system is unable to parse the CARLAR log" 
			$outBody = $outBody + " file.<br>Either there is no CARLAR log file,"
			$outBody = $outBody + " or the monitoring system is unable to connect"
			$outBody = $outBody + " to it.<br><br>If this issue persists please"
			$outBody = $outBody + " contact your System Administrator."
		}
		'Recover'		{ 
			$outBody = "The monitoring system is now able to parse the CARLAR" 
			$outBody = $outBody + " log file.<br>The monitoring system has"
			$outBody = $outBody + " recovered successfully."
		}
		'No Error'		{ 
			$outBody = "Service has been restarted.<br>" 
			$outBody = AddErrorToString $fxml $outBody
		}
		'Many Files'		{ 
			$outBody = '<font color="red">File count is over the threshold please'
			$outBody = $outBody + ' check IPFArchive Import Service on'
			$outBody = $outBody + ' DC-FS01.DC.BLUEPOINT.COM!<br></font>'
		}
		'Error Files'		{ 
			$outBody = '<font color="red">There is an Invalid or Aborted file '
			$outBody = $outBody + 'for NME please check IPFArchive Import '
			$outBody = $outBody + 'Folders on DC-FS01.DC.BLUEPOINT.COM!<br></font>'
		}
		'No Files'		{ 
			$outBody = '<font color="red">Unable to contact IPFArchive Import'
			$outBody = $outBody + ' folder at this time.<br></font>'
		}
		'Files Recovery'		{ 
			$outBody = "The monitoring system is now able to connect to the" 
			$outBody = $outBody + " IPFA Import folder.<br>The monitoring system"
			$outBody = $outBody + "  has recovered successfully."
		}
		default			{
			$outBody = "OMG we are all going to die!<br>Something really wrong"
			$outBody = $outBody + " happened in the monitoring script."
		}
	}
	$outBody
}
################################################################################

function SendMail ( [string]$mailCase ){
#	creaets and EMAIL

	$mailBody = CreateEMAILBody $mailXML $mailCase
	Write-Host $mailBody
	CreateEmailXML $mailXML $mailCase $mailBody
}