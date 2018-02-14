################################################################################
#
# Run Local PowerShell on Remote workstation:
#
# Online Resources:
#   http://mikefrobbins.com/2018/01/04/using-powershell-to-check-remote-windows-systems-for-cve-2017-5754-meltdown-and-cve-2017-5715-spectre/
#
# Coded By:
#	Chris Brinkley
#
# Version:
#	1.0.0 	- 01/08/2018 -	Initial Build.
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
    Write-Host "1)> Run-LocalRemote Production"
    Write-Host "   Searches for *Production* named OUs using the default credentials."
    Write-Host "2)> Run-LocalRemote -OUNameFilter Staging_srv -Credential cbrinkley"
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
    $ComputerName = Get-ADComputer -SearchBase $OU -Filter { OperatingSystem -Like '*Windows Server 2012*' }  -Server $DomainServer -Property Name | Select-Object -ExpandProperty DNSHostName
    if($ComputerName){
        foreach($computer in $ComputerName){
            Invoke-Command -ComputerName $computer -Credential $Cred ${function:Get-SpeculationControlSettings} -erroraction 'silentlycontinue'  | Export-Csv -noType -Append -Path "LocalRemote.CSV" -force 
            # Command is run on each Computer so you need to make sure that
            #   PSRemoting is enabled and that the user has admin access.  
        }
    } 
}