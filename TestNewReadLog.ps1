################################################################################
# Variable Declarations
################################################################################
$instLoc = split-path -parent $MyInvocation.MyCommand.Definition



################################################################################
# Function Declarations
################################################################################
function ReadXMLFile ([xml]$fxml, [string]$inFile) {

	try {
		$fxml.Load($inFile)
	} catch {
		Write-Host "Missing XML File:" $inFile
		exit
	}
}
################################################################################
function GetXMLValue ([xml]$fxml, [string]$getValueName) {

	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq $getValueName
		} | ForEach-Object { $getValue = $_.value } |Out-Null
		
	if ( $getValue ){
#	if Node Exists
		return $getValue
	} else {
		Write-Host "Missing XML Parameter: $getValueName from file: $settingXML"
		continue
	}
}
################################################################################
function SetXMLValue ([xml]$fxml, [string]$SetValueName, [string]$SetValue) {

	$test = GetXMLValue $fxml $SetValueName
#	Check is Node exists

	$fxml.ReadLogFile.Setting |  Where-Object { $_.name -eq $SetValueName
		} | ForEach-Object { $_.value = $SetValue } |Out-Null
}
################################################################################


################################################################################
# Main Program
################################################################################
if ( $args.Length ){
	Write-Host "Num Args:" $args.Length;
} else {
	Write-Host "No Args"
	exit
}

ForEach ($arg in $args) {
	$settingXML = $instLoc + "\" + $arg
	Write-Host "Using XML File:" $settingXML;
	
	$setXML = New-Object XML
	
	ReadXMLFile $setXML $settingXML
#	Reads Settings XML file
	
	$testValue = GetXMLValue $setXML "ServerName"
	Write-Host "ServerName:" $testValue;

	
	SetXMLValue $setXML "ServerName" "Bob"
	
	$testValue = GetXMLValue $setXML "ServerName"
	Write-Host "ServerName:" $testValue;

}
