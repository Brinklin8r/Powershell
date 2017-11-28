################################################################################
#
# File Counter:
#	Counts the number of files in a specified folder and if that is over a 
#	defined threshold it sends an e-mail.
#
#
# Coded By:
#	Chris Brinkley
#
# Version:
#	1.2.2	- 10/06/2014 -	Moved file to TAM5
#							Updated for OGO servers.
#	1.2.1	- 02/13/2014 - 	Moving files to TAM-MON for monitoring
#	1.2.0	- 07/19/2013 - 	Added Check for InvalidFiles and AbortedFiles folder 
#	1.1.0	- 04/26/2013 - 	Created include files to break out Email and XML 
#							functions.
#	1.0.0 	- 04/10/2013 -	Initial Build.
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
$uncServer = "\\dc-fs01.dc.bluepoint.com"
$uncFullPath = "$uncServer\check"
$uName = "bp_domain\tamphone"
$pWord = "TamPS1221"

net use $uncServer $pWord /user:$uName

################################################################################

$settingXML = $instLoc + "\CountDir.XML"
#		XML Settings file.
$mailfXML = $instLoc + "\Mail.XML"
#		XML Settings file.

$fileCount = 0
if ( $testing ){
	$countDir = "\\TAM-Mon\CARLARService"
	$inCountDir = $countDir + "\InvalidFiles"
	$abCountDir = $countDir + "\AbortedFiles"
} else {
	$countDir = "\\dc-fs01.dc.bluepoint.com\Check\Import\X937\NMEDU"
	$inCountDir = $countDir + "\InvalidFiles"
	$abCountDir = $countDir + "\AbortedFiles"
}

################################################################################
# Include External Files
################################################################################
. ($instLoc + "\EmailInclude.ps1")
. ($instLoc + "\XMLInclude.ps1")

################################################################################
# Function Declarations
################################################################################

################################################################################
# Main Program
################################################################################
$logingDate = Get-Date -Format "MMddyyyy"
$logpath = "e:\bin\log" + $logingDate + ".txt"
Start-Transcript -Path $logpath -Append -Verbose
#	Cheap Logging!
Write-Host "Starting CountDir.PS1"

$setXML = New-Object XML
$setXML = ReadXMLFile $setXML $settingXML
#	Reads Settings XML file
$mailXML = New-Object XML	
$mailXML = ReadXMLFile $mailXML $mailfXML 
#	Reads Mail Settings XML file

$foldCount = GetXMLSetting $setXML "FolderCount"
$countThreshold = GetXMLSetting $setXML "Threshold"
$lastRead = GetXMLSetting $setXML "GoodRead"
$dirExist = (Test-Path $countDir)
# 	check that the directory exists.

if ($dirExist) {
	$fileCount = (get-childitem $countDir -name).count - $foldCount
# 	This count includes directories so we adjust the count
	$invFCount = (get-childitem $inCountDir -name).count - 1
# 	This count includes directories so we adjust the count
	$aboFCount = (get-childitem $abCountDir -name).count - 1
# 	This count includes directories so we adjust the count
	if ( $invFCount -lt 0 ) {
		$invFCount = 0
	}
	if ( $aboFCount -lt 0 ) {
		$aboFCount = 0
	}


	Write-Host $countDir
	Write-Host "Directory file count: $fileCount"
	Write-Host "InvalidFiles Directory file count: $invFCount"
	Write-Host "AbortedFiles Directory file count: $aboFCount"
	if ( $lastRead -ne '1') { 
		SendMail 'Files Recovery'
		SetXMLSetting $setXML "GoodRead" 1
	}
	SetXMLSetting $setXML "FileCount" $fileCount
	SetXMLSetting $setXML "LastCheck" "Now"
	if ( $fileCount -ge $countThreshold ) {
		SendMail 'Many Files'
		SetXMLSetting $setXML "LastEmail" "Now"
	}
	if ( ( $invFCount -ne 0 ) -or ( $aboFCount -ne 0 ) ) {
		SendMail 'Error Files'
		SetXMLSetting $setXML "LastEmail" "Now"	
	}
	
} else {
# 	No Directory
	if ( $lastRead -eq '1') { 
		SendMail 'No Files'
		SetXMLSetting $setXML "GoodRead" 0
		SetXMLSetting $setXML "FileCount" $fileCount
	}
}

if ( $testing ){
} else{
	$setXML.Save($settingXML)
}	# Saves new settings.
Write-Host "XML Saved"
#	Used for testing
net use $uncServer $pWord /user:$uName
#	Delete Maped Drive