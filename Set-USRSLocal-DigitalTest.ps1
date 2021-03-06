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
$done = AddLUser 'CWijayawardhana' 'Administrators' 'Charles Wijayawardhana' 'Test Only'
$done = AddLUser 'Chris.Zamarripa' 'Administrators' 'Chris Zamarripa' 'Test Only'
$done = AddLUser 'Manuel.Gonzales' 'Administrators' 'Manuel Gonzales' 'Test Only'
$done = AddLUser 'Megan.Correa' 'Administrators' 'Megan Correa' 'Test Only'
$done = AddLUser 'Patrick.Downey' 'Administrators' 'Patrick Downey' 'Test Only'
$done = AddLUser 'Tyler.Kempton' 'Administrators' 'Tyler Kempton' 'Test Only'
$done = AddLUser 'Mauro.Zabala' 'Administrators' 'Mauro Zabala' 'Test Only'
