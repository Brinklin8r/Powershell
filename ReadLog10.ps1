################################################################################
#
# Log Parser:
#	Reads a logfile, looking for a keyword(s) and if it finds it an e-mail with 
#	the error message(s) attached is sent.
#
# Online Resources:
#	http://knowledgevoid.com/blog/2012/12/05/log-parsing-and-email-notification-in-powershell/
#	http://stackoverflow.com/questions/1252335/send-mail-via-gmail-with-powershell-v2s-send-mailmessage
#
# Coded By:
#	Chris Brinkley
#
# Version:
#	2.2.3	- 01/07/2015 -	Added test case for if the log file does not exists
#							but the Network Sare is accessable, for IT.
#	2.2.2	- 02/13/2014 - 	Moving files to TAM-MON for monitoring
#	2.2.1	- 04/10/2013 -	Code Cleanup
#							Function cleanup
#	2.2.0	- 04/09/2013 -	Send an email upon recovery from not able to read
#							CAR/LAR log file.
#	2.1.4	- 02/26/2013 -	HTML Emails w/ basic formating
#	2.1.3	- 02/26/2013 -	Update wording for NO CARLAR e-mail. 
#	2.1.2	- 02/20/2013 -	E-mail Settings from XML. 
#							Function rebuild to accept XML object.
#							Clean up some code.
#							Added Testing Key.
#	2.1.1	- 02/20/2013 -	Fixed error Message about converting "" to DateTime.
#	2.1.0	- 02/19/2013 - 	Added search for Service is Started messages in log.
#							* This was a feature request from David P.
#	2.0.0	- 02/19/2013 -	Read and write config info to XML files.
#							Only sends new errors in Body of email.
#	1.2.4	- 02/12/2013 - 	Exit if no log file is found, but do not change
#							error counter.
#	1.2.3	- 02/08/2013 -	Changed to Reg-Ex filter for Error checking.
#	1.2.2	- 01/29/2012 -	Error checking for no log file.
#	1.2.1	- 01/28/2013 -	Fixed secure authentication.
#	1.2.0	- 01/24/2013 -	Created Functions.
#							Secure Password.
#							Added more comments and code clean up.
#	1.0.1 	- 01/22/2013 -	Added comments and cleaned up code.
#	1.0.0 	- 01/18/2013 -	Initial Build.
#
################################################################################

################################################################################
# Variable Declarations
################################################################################
$instLoc = split-path -parent $MyInvocation.MyCommand.Definition
$testing = $false
#$testing = $true

################################################################################
# Map Network Drive
################################################################################
$uncServer = "\\dc-app10.dc.bluepoint.com"
$uncFullPath = "$uncServer\CARLARService"
$uName = "bp_domain\tamphone"
$pWord = "TamPS1221"

net use $uncServer $pWord /user:$uName

################################################################################
$lgDate = Get-Date -Format "MMddyyyy"
if ( $testing ){
	$logFile = "\\TAM-Mon\CARLARService\CheckPlusService.log"
} else {
	$logFile = $uncFullPath+"\Logs\Logging"+$lgDate+".log"
}
$logPatern = '\b=\d+$\b'
#		Text to search for in file
#	 	In the case of: =#<EOL>
$logStartPat = 'Service is started'
#		Text to search for in file
#	 	In the case of: Service is started
$settingXML = $instLoc + "\ReadLog10.XML"
#		XML Settings file.
$mailfXML = $instLoc + "\Mail.XML"
#		XML Settings file.

################################################################################
# Function Declarations
################################################################################
function ReadXMLFile ([xml]$fxml, [string]$inFile) {

	try {
		$fxml.Load($inFile)
	} catch {
		Write-Host "Missing XML File:" $inFile
		if ($inFile = $settingXML){
			$tmpStr = "<ReadLogFile>"
			$tmpStr = $tmpStr + "<Setting><name>ErrorCount</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>ResetCount</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>LastCheck</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>LastEmail</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>GoodReadt</name><value>1</value></Setting>"
			$tmpStr = $tmpStr + "<Error><eValue>new</eValue></Error>"
			$tmpStr = $tmpStr + "</ReadLogFile>"
			[xml]$fxml = $tmpStr
		} else{
			exit
		}
	}
}
################################################################################

function AddErrorToString ([xml]$fxml, [string]$outBody){
#	Takes in an XML object and makes a String.

	$fxml.ReadLogFile.Error |  Where-Object { $_.eValue -ne '' 
		} | ForEach-Object {$outBody = $outBody + $_.eValue + "<br>" } |Out-Null
	$outBody = $outBody + "<br><br>Last e-mail sent:  "
	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'LastEmail'
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
		'No CarLar Log' {
			$outBody = "The monitoring system is unable to parse the CARLAR log" 
			$outBody += " file " + $logFile + ".<br>There is no CARLAR log file,"
			$outBody += " but the monitoring system is able to connect"
			$outBody += " to the share.<br><br>If this issue persists please"
			$outBody += " contact your System Administrator."
		}
		'No CarLar'		{ 
			$outBody = "The monitoring system is unable to parse the CARLAR log" 
			$outBody += " file " + $logFile + ".<br>Either there is no CARLAR log file,"
			$outBody += " or the monitoring system is unable to connect"
			$outBody += " to it.<br><br>If this issue persists please"
			$outBody += " contact your System Administrator."
		}
		'Recover'		{ 
			$outBody = "The monitoring system is now able to parse the CARLAR" 
			$outBody += " log file " + $logFile + ".<br>The monitoring system has"
			$outBody += " recovered successfully."
		}
		'No Error'		{ 
			$outBody = "Service has been restarted.<br>" 
			$outBody = AddErrorToString $fxml $outBody
		}
		'Channel Error'		{ 
			$outBody = "New Channel errors since last email:<br><br>" 
			$outBody = AddErrorToString $fxml $outBody
			$outBody += "<br><br>Please note that the above times are"
			$outBody += " Eastern Time."
		}
		'No Channel Error'		{ 
			$outBody = "Service has been restarted.<br>" 
			$outBody = AddErrorToString $fxml $outBody
		}
		'No SSOLog'		{ 
			$outBody = "The monitoring system is unable to parse the SSO log" 
			$outBody += " file.<br>Either there is no SSO log file,"
			$outBody += " or the monitoring system is unable to connect"
			$outBody += " to it.<br><br>If this issue persists please"
			$outBody += " contact your System Administrator."
		}
		default			{
			$outBody = "OMG we are all going to die!<br>Something really wrong"
			$outBody += " happened in the monitoring script."
		}
	}
	$outBody
}
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

function ClearErrors ([xml]$fxml){
#	Clears old messages from the XML object.

	try {
		$fxml.ReadLogFile.Error |  Where-Object { $_.eValue -ne '' 
			} | ForEach-Object { $fxml.ReadLogFile.RemoveChild($_) } |Out-Null
	} catch {
#		No Error messages in the XML object.
	}
	Write-Host	"Processed XML"
#		Used for testing
}
################################################################################

function UpdateXML([array]$flines, [array]$sflines, [xml]$fxml) {
#	Updates the XML object with the current number of errors, Current Date
#	and Time, and the actuall Error messages.

	$errCount = 0
	$rstCount = 0
	$NowDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$myMatch = ",[^\n]*"
	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'LastEmail' 
		} | ForEach-Object { $CheckDate = $_.value } |Out-Null
	
	foreach($line in $flines){
#		foreach($cline in $line.context.DisplayPrecontext){
#			If first part of the string (timestamp) is after LastEmail date/time
			$dtStamp = ($line.Line -replace $myMatch)
			if ( $dtStamp -ne ""){
				if ( (get-date $dtStamp) -gt (get-date $CheckDate)){
					$newError = $fxml.CreateElement('Error')
					$newError.SetAttribute('eValue',[string]$line.Line)
					$fxml.ReadLogFile.AppendChild($newError)|Out-Null
					$errCount = $errCount + 1
				}
			}
#		}
	}
	$newError = $fxml.CreateElement('Error')
	$newError.SetAttribute('eValue','<font color="red">')
	$fxml.ReadLogFile.AppendChild($newError)|Out-Null

	foreach($sline in $sflines){
#		foreach($scline in $sline.context.DisplayPrecontext){
#			If first part of the string (timestamp) is after LastEmail date/time
			$dtStamp = ($sline.Line -replace $myMatch)
			if ( $dtStamp -ne ""){
				if ( (get-date $dtStamp) -gt (get-date $CheckDate)){
					$newError = $fxml.CreateElement('Error')
					$newError.SetAttribute('eValue',[string]$sline.Line)
					$fxml.ReadLogFile.AppendChild($newError)|Out-Null
					$rstCount = $rstCount + 1
				}
			}
#		}
	}
	$newError = $fxml.CreateElement('Error')
	$newError.SetAttribute('eValue','</font>')
	$fxml.ReadLogFile.AppendChild($newError)|Out-Null

#		Adds new messages to the XML object.
	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'ErrorCount' 
		} | ForEach-Object { $_.value = [string]$errCount } |Out-Null
#		Updates Error Count to the XML object.
	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'ResetCount' 
			} | ForEach-Object { $_.value = [string]$rstCount } |Out-Null
#		Updates Reset Count to the XML object.
	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'LastCheck' 
		} | ForEach-Object { $_.value = [string]$NowDate } |Out-Null
#		Saves Current Date and Time to the XML object.
	Write-Host "XML Updated"
#		Used for testing
}
################################################################################

function BadRead ([xml]$fxml){
#	Update GoodReed to 0 and save XML 

	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'GoodRead' 
		} | ForEach-Object { $_.value = '0' } |Out-Null

	if ( $testing ){
	} else{
		$fxml.Save($settingXML)
	}	# Saves new settings.
	Write-Host "XML Saved"
#		Used for testing
}
################################################################################

function ReadFromLogFile ([string]$flogFile, [string]$flogPat ){

	try {
		$fLines = Select-String -path $flogFile -Pattern $flogPat -AllMatches
#		Creates an object that contains ALL of the lines that have the pattern
#		text.
	} catch {
#		Incase there is no Log file.
		Write-Host "No Log File"
#		Used for testing

		$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'GoodRead' 
			} | ForEach-Object { $goodread = $_.value } |Out-Null
		
		if ( $goodread -ne 1 ){
#			If there was already a bad read no need to send another e-mail.
			exit
		} else {
			if (Test-Path $uncFullPath) {
				$mailCase = 'No CarLar Log'
			} else {
				$mailCase = 'No CarLar'
			}
			$mailBody = CreateEMAILBody $setXML $mailCase
			Write-Host $mailBody
			CreateEmailXML $mailXML $mailCase $mailBody
			BadRead $setXML
			exit
		}
	}
	$fLines
}

################################################################################
# Main Program
################################################################################
$logingDate = Get-Date -Format "MMddyyyy"
$logpath = "e:\bin\log" + $logingDate + ".txt"
Start-Transcript -Path $logpath -Append -Verbose
#	Cheap Logging!
Write-Host "Starting ReadLog10.PS1"

$setXML = New-Object XML
ReadXMLFile $setXML $settingXML
#	Reads Settings XML file

$mailXML = New-Object XML	
ReadXMLFile $mailXML $mailfXML 
#	Reads Mail Settings XML file

$lines = ReadFromLogFile $logFile $logPatern 
#	Reads LOG file for Errors
Write-Host "Errors Retrieved"

$startLines = ReadFromLogFile $logFile $logStartPat 
#	Reads LOG file for Service Restarts
Write-Host "Start Messages Retrieved"

$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'GoodRead' 
	} | ForEach-Object { $goodread = $_.value } |Out-Null

if ( $goodread -ne 1){
#	If GoodRead is not 1 ( meaning there was a read error last time) send the
#	Recovery e-mail.
	$mailCase = 'Recover'
	$mailBody = CreateEMAILBody $setXML $mailCase
	Write-Host $mailBody
	CreateEmailXML $mailXML $mailCase $mailBody
	$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'GoodRead' 
		} | ForEach-Object { $_.value = '1' } |Out-Null
	Write-Host "Recovery from No Log File"
#		Used for testing
}

ClearErrors $setXML
UpdateXML $lines $startLines $setXML

$errorCount = 0
$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'ErrorCount' 
	} | ForEach-Object { $errorCount = $_.value } |Out-Null

$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'ResetCount' 
	} | ForEach-Object { $resetCount = $_.value } |Out-Null

if( $errorCount -ne 0 -or $resetCount -ne 0){
	$Now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	if ( $errorCount -ne 0) {
		$mailCase = 'CarLar Error'
	} else {
		$mailCase = 'No Error'
	}
	$mailBody = CreateEMAILBody $setXML $mailCase
	Write-Host $mailBody 
	CreateEmailXML $mailXML $mailCase $mailBody
	$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'LastEmail' 
		} | ForEach-Object { $_.value = [string]$Now } |Out-Null
}

if ($lines) {
	Write-Host $lines.count "Errors Found in" $logFile
} else {
	Write-Host "No Errors Found in" $logFile
}
if ( $testing ){
} else{
	$setXML.Save($settingXML)
}	# Saves new settings.
Write-Host "XML Saved"
#	Used for testing
net use $uncServer /delete
#	Delete Mapped Drive