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
    $Pass = ConvertTo-SecureString '$unflow3r' -AsPlainText -Force

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
            $objUser.setpassword('$unflow3r')
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
$done = AddLUser 'cbrinkley' 'Administrators' 'Chris Brinkley' 'Datacenter Admin'
$done = AddLUser 'jmonk' 'Administrators' 'Judit Monk' 'Datacenter Admin'
$done = AddLUser 'BPierce' 'Administrators' 'Brandon Pierce' 'IT Manager'
$done = AddLUser 'JGrinzivich' 'Administrators' 'John Grinzivich' 'Escalations'
$done = AddLUser 'rlincoln' 'Administrators' 'Robert Lincoln' 'Escalations'
$done = AddLUser 'dkim' 'Administrators' 'Dawn Kim' 'Tam Lead'
$done = AddLUser 'MDeFilippo' 'Administrators' 'Mark DeFilippo' 'Tam Lead'
#$done = AddLUser 'MGilligan' 'Remote Desktop Users' 'Michael Gilligan' 'PS Implementor'
#$done = AddLUser 'sgeorgens' 'Remote Desktop Users' 'Scott Georgens' 'PS Implementor'
