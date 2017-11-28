################################################################################
#
# Get Powershell version:
#	Queries AD and returns a list og OUs that match the search terms.
#   Queries each OU returned to get a list of the Computers it contains.   
#	Queries each Computer and returns its Powershell/WMF version
#   Puts that list into a CSV.
#
# Online Resources:
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
$OUFilter = "Name -like 'Production*'"
# 'OU=Production,dc=dc,dc=bluepoint,dc=com', 
# 'OU=Production_srv_Fastdocs,dc=dc,dc=bluepoint,dc=com',
# 'OU=Production_srv_Foundation,dc=dc,dc=bluepoint,dc=com' 

################################################################################
# Main Program
################################################################################
$OUs = Get-ADOrganizationalUnit -Filter $OUFilter -Server $DomainServer |  Select-Object -ExpandProperty DistinguishedName

foreach($OU in $OUs){
    $ComputerName = Get-ADComputer -SearchBase $OU -Filter '*' -Server $DomainServer -Propert Name | Select-Object -ExpandProperty DNSHostName
    if($ComputerName){
        foreach($computer in $ComputerName){
            Invoke-Command -ComputerName $computer -Credential $Cred -ScriptBlock {$PSVersionTable.PSVersion} -erroraction 'silentlycontinue'  | Export-Csv -Append -Path "PSVersion.CSV" -force 
            # Command is run on each Computer so you need to make sure that
            #   PSRemoting is enabled and that the user has admin access.  
        }
    } 
}