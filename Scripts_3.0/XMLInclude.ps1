################################################################################
#
# XML Function Include:
#	These are some base XML function that is reused.
#	I created this to be included into other programs.
#
# Online Resources:
#	http://www.energizedtech.com/2010/03/powershell-using-split-to-extr.html
#
# Coded By:
#	Chris Brinkley
#
# Version:
#	1.0.0 	- 04/16/2013 -	Initial Build.
#
################################################################################

function ReadXMLFile ([xml]$fxml, [string]$inFile) {
#	Reads settings from XML file.

	try {
		$fxml.Load($inFile)
	} catch {
		Write-Host "Missing XML File: $inFile"
		CreateBlankXML $fxml $inFile
	}
	$fxml
}
################################################################################

function CreateBlankXML ([xml]$fxml, [string]$inFile) {
#	Creates a Blank XML Settigns file.

	$PIECES = $inFile.split(“\”) 
	$NUMBEROFPIECES = $PIECES.Count 
	$inFile = $PIECES[$NumberOfPieces-1] 
	
	$tmpStr = "<SettingXMLFile>"
	switch ( $inFile ) {
		'ReadLog.xml'	{ 
			$tmpStr = $tmpStr + "<Setting><name>ErrorCount</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>ResetCount</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>LastCheck</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>LastEmail</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>GoodRead</name><value>1</value></Setting>"
			$tmpStr = $tmpStr + "<Error><eValue>new</eValue></Error>"
		}
		'CountDir.xml'	{
			$tmpStr = $tmpStr + "<Setting><name>FolderCount</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>Threshold</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>FileCount</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>LastCheck</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>LastEmail</name><value>0</value></Setting>"
			$tmpStr = $tmpStr + "<Setting><name>GoodRead</name><value>1</value></Setting>"
		}
		Default	{
			exit
		}
	}
	$tmpStr = $tmpStr + "</SettingXMLFile>"
	
	[xml]$fxml = $tmpStr
	
	$fxml
}
################################################################################

function UpdateXML([array]$flines, [array]$sflines, [xml]$fxml) {
#	Updates the XML object with the current number of errors, Current Date
#	and Time, and the actuall Error messages.

	$errCount = 0
	$rstCount = 0
	$myMatch = ",[^\n]*"
	$CheckDate = GetXMLSetting $fxml 'LastEmail'
	
	foreach($line in $flines){
		foreach($cline in $line.context.DisplayPrecontext){
#			If first part of the string (timestamp) is after LastEmail date/time
			$dtStamp = ($line.Line -replace $myMatch)
			if ( $dtStamp -ne ""){
				if ( (get-date $dtStamp) -gt (get-date $CheckDate)){
					$newError = $fxml.CreateElement('Error')
					$newError.SetAttribute('eValue',[string]$line.Line)
					$fxml.SettingXMLFile.AppendChild($newError)|Out-Null
					$errCount = $errCount + 1
				}
			}
		}
	}
	$newError = $fxml.CreateElement('Error')
	$newError.SetAttribute('eValue','<font color="red">')
	$fxml.SettingXMLFile.AppendChild($newError)|Out-Null

	foreach($sline in $sflines){
		foreach($scline in $sline.context.DisplayPrecontext){
#			If first part of the string (timestamp) is after LastEmail date/time
			$dtStamp = ($sline.Line -replace $myMatch)
			if ( $dtStamp -ne ""){
				if ( (get-date $dtStamp) -gt (get-date $CheckDate)){
					$newError = $fxml.CreateElement('Error')
					$newError.SetAttribute('eValue',[string]$sline.Line)
					$fxml.SettingXMLFile.AppendChild($newError)|Out-Null
					$rstCount = $rstCount + 1
				}
			}
		}
	}
	$newError = $fxml.CreateElement('Error')
	$newError.SetAttribute('eValue','</font>')
	$fxml.SettingXMLFile.AppendChild($newError)|Out-Null
#		Adds new messages to the XML object.
	SetXMLSetting $fxml 'ErrorCount' [string]$errCount
#		Updates Error Count to the XML object.
	SetXMLSetting $fxml 'ResetCount' [string]$rstCount
#		Updates Reset Count to the XML object.
	SetXMLSetting $fxml 'LastCheck' 'Now'
#		Saves Current Date and Time to the XML object.
	Write-Host "XML Updated"
#		Used for testing
}
################################################################################

function GetXMLSetting ([xml]$fxml, [string]$setName) {
#	Reads the value of an XML Setting

	$outSetting = ""	
	$fxml.SettingXMLFile.Setting |  Where-Object { $_.name -eq $setName 
		} | ForEach-Object { $outSetting = $_.value } |Out-Null

	if ( $outSetting -eq "" ){
		Write-Host "Missing Setting $setName in XML file."
		exit
	}
	$outSetting
}
################################################################################

function SetXMLSetting ([xml]$fxml, [string]$setName, [string]$setVal) {
#	Sets the value of an XML Setting

	$notSet = 1
	if ( $setVal -eq "Now" ) {
		$setVal = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	}
	$fxml.SettingXMLFile.Setting |  Where-Object { $_.name -eq $setName 
		} | ForEach-Object { 
			$_.value = [string]$setVal
			$notSet = 0	
		} |Out-Null
	if ( $notSet ){
		Write-Host "Missing Setting $setName in XML file."
		exit
	}
}
################################################################################