################################################################################
#
# Get all installed .NET versions:
#	Queries AD and returns a list og OUs that match the search terms.
#   Queries each OU returned to get a list of the Computers it contains.   
#	Queries each Computer and returns its NET versions.
#   Puts that list into a CSV, and creates files with what Computer are Online and Offline
#
# Online Resources:
#   https://www.powershelladmin.com/wiki/List_installed_.NET_versions_on_remote_computers#
#
# Coded By:
#	Chris Brinkley
#
# Version:
#   1.2.0   - 11/28/2017 -  Added Help text
#                           Code and Comment clean-up
#   1.1.0   - 11/20/2017 -  Parameterization
#                           Added ability to enter you own credentials.
#	1.0.0 	- 11/15/2017 -	Initial Build.
#
################################################################################

################################################################################
# Parameter Declarations
################################################################################
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
        [string]$OUNameFilter = @(),

    [System.Management.Automation.PSCredential]$Credential,
    [string]$DomainServer = "DC.Bluepoint.COM",
    # Should be DC.Bluepoint.COM, but Production DC servers do not have access to
    #   query their domain controller.
    
    [switch]$Help
)

################################################################################
# Variable Declarations
################################################################################
$OUFilter = "Name -like '*" + $OUNameFilter +"*'"

################################################################################
# Main Program
################################################################################
if ($Help){
    Write-Host "Hope this Helps ;)"
    Write-Host "====================="
    Write-Host "-OUNameFilter <Mandatory> [STRING]  'The OUs will use this string to do a LIKE search.'"
    Write-Host "-Credential   <Optional>  [STRING]  'UserName to query the Computer.  Must have admin rights on the Computer'"
    Write-Host "-DomainServer <Optional>  [STRING]  'Server name of Domain Controller to query.'"
    Write-Host "-Help         <Optional>"
    Write-Host " "
    Write-Host " "
    Write-Host "EXAMPLES:"
    Write-Host "1)> Get-NETVer Production"
    Write-Host "   Searches for *Production* named OUs using the default credentials."
    Write-Host "2)> Get-NETVer -OUNameFilter Staging_srv -Credential cbrinkley"
    Write-Host "   Searches for *Staging_srv* named OUs using the entered credentials of CBRINKLEY."
	exit
}

if ($Credential) {
    $Cred = $Credential
} else {
    # If no credentials are Supplied use TamPhone
    $UserName = "BP_Domain\TamPhone"
    $PWord = ConvertTo-SecureString -String "TamPS1221" -AsPlainText -Force
    $Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $UserName, $PWord
}

$OUs = Get-ADOrganizationalUnit -Filter $OUFilter -Server $DomainServer |  Select-Object -ExpandProperty DistinguishedName

foreach($OU in $OUs){
    $ComputerName = Get-ADComputer -SearchBase $OU -Filter '*' -Server $DomainServer -Property Name | Select-Object -ExpandProperty DNSHostName
    if($ComputerName){
        # Check to see if there are Computers in the OU.  If not skip to next OU
        Import-Module -Name DotNetVersionLister -ErrorAction Stop
        Get-DotNetVersion -ComputerName $ComputerName -PSRemoting -Credential $Cred -ContinueOnPingFail -ExportToCSV
        Start-Sleep -s 70
        # Pause So files are not overwritten
    } 
}