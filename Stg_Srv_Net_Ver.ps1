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
#	1.0.0 	- 11/15/2017 -	Initial Build.
#
################################################################################

################################################################################
# Variable Declarations
################################################################################
$User = "BP_Domain\TamPhone"
$PWord = ConvertTo-SecureString -String "TamPS1221" -AsPlainText -Force
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

$DomainServer = "DC.Bluepoint.COM"
# Should be DC.Bluepoint.COM, but Production DC servers donot have access to
#   query their domain controler.
$OUFilter = "Name -like 'Staging_Srv*'"
# 'OU=Staging_Srv,dc=dc,dc=bluepoint,dc=com', 
# 'OU=Staging_Srv_Fastdocs,dc=dc,dc=bluepoint,dc=com',
# 'OU=Staging_Srv_Foundation,dc=dc,dc=bluepoint,dc=com' 

################################################################################
# Main Program
################################################################################
$OUs = Get-ADOrganizationalUnit -Filter $OUFilter -Server $DomainServer |  Select-Object -ExpandProperty DistinguishedName

foreach($OU in $OUs){
    $ComputerName = Get-ADComputer -SearchBase $OU -Filter '*' -Server $DomainServer -Propert Name | Select-Object -ExpandProperty DNSHostName
    if($ComputerName){
        # Check to see if there are COmputers in the OU
        Import-Module -Name DotNetVersionLister -ErrorAction Stop
        Get-DotNetVersion -ComputerName $ComputerName -PSRemoting -Credential $Cred -ContinueOnPingFail -ExportToCSV 
        Start-Sleep -s 70
        # So files are not overwriten
    } 
}
