################################################################################
#
# Get whom is logged into which server.
#
# Online Resources:
#
# Coded By:
#	Chris Brinkley
#
# Version:
#   1.0.1   - 12/19/2017 -  Fixed spelling mistake.
#	1.0.0 	- 12/18/2017 -	Initial Build.
#
################################################################################

################################################################################
# Parameter Declarations
################################################################################
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
        [string]$OUNameFilter = @(),

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
    Write-Host "-DomainServer <Optional>  [STRING]  'Server name of Domain Controller to query.'"
    Write-Host "-Help         <Optional>  [SWITCH]  'This screen.'"
    Write-Host " "
    Write-Host " "
    Write-Host "EXAMPLES:"
    Write-Host "1)> Get-LoggedIn Production"
    Write-Host "   Searches for *Production* named OUs and displays whom is logged in per server."
	exit
}

$OUs = Get-ADOrganizationalUnit -Filter $OUFilter -Server $DomainServer |  Select-Object -ExpandProperty DistinguishedName

foreach($OU in $OUs){
    $ComputerList= Get-ADComputer -SearchBase $OU -Filter '*' -Server $DomainServer -Property Name | Sort-Object DNSHostname | Select-Object -ExpandProperty DNSHostName
    if($ComputerList){
        # Check to see if there are Computers in the OU.  If not skip to next OU
        foreach ($Server in $ComputerList) {
            Write-Host "`nSessions found on $Server :" -ForegroundColor Red -BackgroundColor Yellow
		    $ErrorActionPreference = "Continue"
		    $QUResult = quser /server:$Server 2>&1
		    $ErrorActionPreference = "Stop"
		    if($QUResult -NotMatch "no user exists for") {
			    if($QUResult -NotMatch "Error") {
				    $QUResult
			    }
            }
        }		
    } 
}