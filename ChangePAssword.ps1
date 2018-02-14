#
# ChangePAssword.ps1
#
#$pass = "C@rtman19"
#$user = "cbrinkley"
#foreach($_ in (Get-Content C:\Servers.txt)){
#$newpass = [ADSI]"WinNT://$_/$user,user"
#$newpass.SetPassword($pass)
#$newpass.SetInfo()
#}

#$cmp=[adsi]"WinNT://$env:dc-web50.dc.bluepoint.com/cbrinkley"
#$cmp.SetPassword('C@rtman19')

#([adsi]"WinNT://$env:dc-web50.dc.bluepoint.com/cbrinkley,user").SetPassword('C@rtman19')




#$LocalUser =[adsi]("WinNT://dc-web90.dc.bluepoint.com/cbrinkley, user") 
#$LocalUser.psbase.invoke("SetPassword", "C@rtman19") 