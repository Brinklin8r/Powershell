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
#	2.2.6	- 10/01/2014 -	Moved to TAM5 for OGO monitoring
#							Updated the Servername
#	2.2.5	- 02/13/2014 - 	Moving files to TAM-MON for monitoring
#	2.2.4	- 01/08/2014 - 	Fixed a Depreciated call in Windows 8/PowerShell 4.0
#	2.2.3	- 06/20/2013 -	Added Count filed to Email Subject
#							Changed search criteria and sender list.
#	2.2.2	- 06/17/2013 -	Updated code for SSO Processor Log
#							Code Cleanup
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
$uncServer = "\\dc-mitek01.dc.bluepoint.com"
$uncFullPath = "$uncServer\logfiles"
$uName = "bp_domain\tamphone"
$pWord = "TamPS1221"

net use $uncServer $pWord /user:$uName

################################################################################
if ( $testing ){
#	$logFile = "\\TAM-Mon\CARLARService\Logging06172013.log"
#	$logFile = "\\TAM-Mon\CARLARService\CLEAN_Logging06172013.log"
#	$logFile = "\\TAM-Mon\CARLARService\ONE_Logging06172013.log"
	$logFile = "\\TAM-Mon\CARLARService\TWO_Logging06172013.log"
} else {
	$logDate = Get-Date -Format "MMddyyyy"
	$logFile = "\\dc-mitek01.dc.bluepoint.com\LogFiles\SSO.ProcessorService\"
	$logFile = $logFile + "Logging" + $logDate + ".log"
}
$logPatern = 'SendMessageToPhone=True, MessageToPhone=A deposit cannot be made at this time. Please try again in a few moments.'
#		Text to search for in file
$settingXML = $instLoc + "\ReadLog2.XML"
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
		'No CarLar'		{ 
			$outBody = "The monitoring system is unable to parse the CARLAR log" 
			$outBody = $outBody + " file:  " + $logFile + "<br>Either there is"
			$outBody = $outBody + " no CARLAR log file, or the monitoring system"
			$outBody = $outBody + " is unable to connect to it.<br><br>If this"
			$outBody = $outBody + " issue persists pleasecontact your System"
			$outBody = $outBody + " Administrator."
		}
		'Recover'		{ 
			$outBody = "The monitoring system is now able to parse the" 
			$outBody = $outBody + " log file:  " + $logFile + "<br>The monitoring"
			$outBody = $outBody + " system has recovered successfully."
		}
		'No Error'		{ 
			$outBody = "Service has been restarted.<br>" 
			$outBody = AddErrorToString $fxml $outBody
		}
		'Channel Error'		{ 
			$outBody = "New Channel errors since last email:<br><br>" 
			$outBody = AddErrorToString $fxml $outBody
			$outBody = $outBody + "<br><br>Please note that the above times are"
			$outBody = $outBody + " Eastern Time."
		}
		'No Channel Error'		{ 
			$outBody = "Service has been restarted.<br>" 
			$outBody = AddErrorToString $fxml $outBody
		}
		'No SSOLog'		{ 
			$outBody = "The monitoring system is unable to parse the SSO log" 
			$outBody = $outBody + " file:  " + $logFile + "<br>Either there is" 
			$outBody = $outBody + " no SSO log file, or the monitoring system is"
			$outBody = $outBody + " unable to connect to it.<br><br>If this"
			$outBody = $outBody + " issue persists please contact your System"
			$outBody = $outBody + " Administrator."
		}
		default			{
			$outBody = "OMG we are all going to die!<br>Something really wrong"
			$outBody = $outBody + " happened in the monitoring script."
		}
	}
	$outBody
}
################################################################################

function CreateEmailXML ([XML]$fxml, [string]$mailCase, [string]$msgBody, [string]$addSubStr = '' ){
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
		if ( $mailCase -eq 'Channel Error' ){
			$msg.To.Add("mpahuta@schoolsfirstfcu.org")
			$msg.To.Add("sbrownrigg@schoolsfirstfcu.org")
			$msg.To.Add("gpiccollo@schoolsfirstfcu.org")
		}
		$msg.To.Add("it@bluepointsolutions.com")
		$msg.To.Add("Dawn.Kim@bluepointsolutions.com")	
		$msg.To.Add("Christopher.Brinkley@bluepointsolutions.com")
	}
	$msg.To.Add($msgTo)
	if ( $addSubStr -ne ''){
		$msgSub = $msgSub + " (" + $addSubStr + ")"
	}
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

function UpdateXML([array]$flines, [xml]$fxml) {
#	Updates the XML object with the current number of errors, Current Date
#	and Time, and the actuall Error messages.

	$errCount = 0
	$rstCount = 0
	$NowDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$myMatch = ":\d\d\d:[^\n]*"
	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq 'LastEmail' 
		} | ForEach-Object { $CheckDate = $_.value } |Out-Null
	
	foreach($line in $flines){
#		foreach($cline in $line.context.DisplayPrecontext){
#			If first part of the string (timestamp) is after LastEmail date/time
			$dtStamp = ($line.Line -replace $myMatch)
			if ( $dtStamp -ne ""){
				$dtstp = get-date $dtStamp
				if ( ($dtstp.addhours(-3)) -gt (get-date $CheckDate)){
					$newError = $fxml.CreateElement('Error')
					$newError.SetAttribute('eValue',[string]$line.Line)
					$fxml.ReadLogFile.AppendChild($newError)|Out-Null
					$errCount = $errCount + 1
				}
			}
#		}
	}
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
			$mailCase = 'No SSOLog'
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
Write-Host "Starting ReadLog2.PS1"

$setXML = New-Object XML
ReadXMLFile $setXML $settingXML
#	Reads Settings XML file

$mailXML = New-Object XML	
ReadXMLFile $mailXML $mailfXML 
#	Reads Mail Settings XML file

$lines = ReadFromLogFile $logFile $logPatern 
#	Reads LOG file for Errors
Write-Host "Errors Retrieved"


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
UpdateXML $lines $setXML

$errorCount = 0
$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'ErrorCount' 
	} | ForEach-Object { $errorCount = $_.value } |Out-Null

$setXML.ReadLogFile.Setting |  Where-Object { $_.name -eq 'ResetCount' 
	} | ForEach-Object { $resetCount = $_.value } |Out-Null

if( $errorCount -ne 0 -or $resetCount -ne 0){
	$Now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	if ( $errorCount -ne 0) {
		$mailCase = 'Channel Error'
	} else {
		$mailCase = 'No Channel Error'
	}
	$mailBody = CreateEMAILBody $setXML $mailCase
	Write-Host $mailBody 
	CreateEmailXML $mailXML $mailCase $mailBody $errorCount
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