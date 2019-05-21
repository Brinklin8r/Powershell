################################################################################
#
# Creates local USER accounts and assigns them to the proper local groups.
#
# Online Resources:
#
# Coded By:
#	Chris Brinkley
#
# Version:
#   1.1.2   - 09/15/2018 -  Added ADMTPDM
#   1.1.1   - 09/05/2018 -  Added TPAdminWG password
#   1.1.0   - 12/12/2017 -  Function and default data created
#	1.0.0 	- 12/08/2017 -	Initial Build.
#
################################################################################

################################################################################
# Function Declarations
################################################################################
function AddLUser ([string] $UName, [string] $Group, [string] $FN, [string] $Des) {
################################################################################
# Create Local Groups and Users.
################################################################################
    if($UName -eq "TPAdminWG" ) {
        $Pass = ConvertTo-SecureString 'Bimm.EG+hpwa1' -AsPlainText -Force
    } elseif($UName -eq "ADTPDM") {
        $Pass = ConvertTo-SecureString 'P@ssw0rd1!' -AsPlainText -Force
    } else {
        $Pass = ConvertTo-SecureString '$unflow3r' -AsPlainText -Force
    }

    Write-Host "=========="
    if ($PSVersionTable.PSVersion.Major -gt 4){
        try { 
            New-LocalUser -Name $UName -Password $Pass -FullName $FN -Description $Des -PasswordNeverExpires -ErrorAction stop 
            Write-Host $UName "Created." 
        } catch {
            Write-Host $UName "Exists."
        }

        try { 
            New-LocalGroup -Name $Group -ErrorAction stop 
            Write-Host $Group "Created." 
        } catch {
            Write-Host $Group "Exists." 
        }

        try { 
            Add-LocalGroupMember -Group $Group -Member $UName -ErrorAction stop 
            Write-Host $UName "Added to" $Group"."  
        } catch {
            Write-Host $UName "already in" $Group"."  
        }
    } else {
        try {
            $ObjOU = [ADSI]"WinNT://$Env:ComputerName"
            $objUser = $objOU.Create("User", $UName)
            if($UName -eq "TPAdminWG" ){
                $objUser.setpassword('Bimm.EG+hpwa1')
            } elseif($UName -eq "ADTPDM") {
                $objUser.setpassword('P@ssw0rd1!')
            } else {
                $objUser.setpassword('$unflow3r')
            }
            $objUser.put("description",$Des)
            $objUser.UserFlags = 65536 # ADS_UF_DONT_EXPIRE_PASSWD
            $objUser.SetInfo() 
            Write-Host $UName "Created." 
        } catch {
            Write-Host $UName "Exists."
        }
        try { 
            $objGroup = [ADSI]"WinNT://$Env:ComputerName/$Group"
            $objGroup.add("WinNT://$Env:ComputerName/$UName")
            $objGroup.SetInfo()
            Write-Host $UName "Added to" $Group"."  
        } catch {
            Write-Host $UName "already in" $Group"."  
        }   
    }

    return 0
}

################################################################################
# Variable Declarations
################################################################################

################################################################################
# Main
################################################################################
#$done = AddLUser 'USERNAME' 'GROUP' 'DISPLAY NAME' 'DESCRIPTION'
$done = AddLUser 'allen.davis' 'Administrators' 'Allen Davis' 'Implementations'
$done = AddLUser 'jason.bruton' 'Administrators' 'Jason Bruton' 'Implementations'
$done = AddLUser 'scott.georgens' 'Administrators' 'Scott Georgens' 'Implementations'
$done = AddLUser 'christopher.henery' 'Remote Desktop Users' 'Christopher Henry' 'Support'
$done = AddLUser 'david.warner' 'Remote Desktop Users' 'David Warner' 'Support'
$done = AddLUser 'derrick.kraus' 'Remote Desktop Users' 'Derrick Kraus' 'Support'
$done = AddLUser 'melissa.skaar' 'Remote Desktop Users' 'Melissa Skaar' 'Support'
$done = AddLUser 'katie.lighthart' 'Remote Desktop Users' 'Katie Lighthart' 'Support'
$done = AddLUser 'emily.lozada' 'Remote Desktop Users' 'Emily Lozada' 'Support'
$done = AddLUser 'roberto.nunez' 'Remote Desktop Users' 'Roberto Nunez' 'Support'
$done = AddLUser 'ron.baca' 'Remote Desktop Users' 'Ron Baca' 'Support'
$done = AddLUser 'jeff.duran' 'Remote Desktop Users' 'Jeff Duran' 'Support'

