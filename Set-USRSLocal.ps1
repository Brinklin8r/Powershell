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
#	1.0.0 	- 12/08/2017 -	Initial Build.
#
################################################################################

################################################################################
# Variable Declarations
################################################################################
$UName = "Testy"
$FN = "Testy McTestington" 
$Pass = ConvertTo-SecureString "Test123456!!" -AsPlainText -Force
$Des = "Automated Test Account" 
$Group = "TestGroup"



################################################################################
# Create Local Groups and Users.
# New-LocalUser -Name $UName -Password $Pass -FullName $FN -Description $Des -PasswordNeverExpires | Add-LocalGroupMember -Group $Group
################################################################################
try { 
    New-LocalUser -Name $UName -Password $Pass -FullName $FN -Description $Des -PasswordNeverExpires -ErrorAction stop 
    Write-Host "User Created." 
} catch {
    Write-Host "User Exists."
}

try { 
    New-LocalGroup -Name $Group -ErrorAction stop 
    Write-Host "Group Created." 
} catch {
     
    Write-Host "Group Exists." 
}

try { 
    Add-LocalGroupMember -Group $Group -Member $UName -ErrorAction stop 
    Write-Host "User Added to Group."  
} catch {
    Write-Host "User already in Group."  
}







