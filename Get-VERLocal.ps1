################################################################################
#
# Get all installed .NET and the current Powershell versions, along with all 
#   the local User Groups and users.   
#	This info is saved into a txt file on the users desktop.
#
# Online Resources:
#   https://stackoverflow.com/questions/3487265/powershell-script-to-return-versions-of-net-framework-on-a-machine
#   https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
#   https://www.petri.com/use-powershell-to-find-local-groups-and-members
#
# Coded By:
#	Chris Brinkley
#
# Version:
# 1.0.1   - 01/23/2019 -  .NET 4.7.2 added
#	1.0.0 	- 11/15/2017 -	Initial Build.
#
################################################################################

################################################################################
# Variable Declarations
################################################################################
$FPath = $env:USERPROFILE + "\desktop\" + $env:computername + "_localaudit_" + (Get-Date).ToString("yyyyMMdd") + ".txt" 
# Put the output file onto YOUR desktop

################################################################################
# Get ALL .NET Versions installed.
################################################################################
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} |
Select-Object PSChildName, Version, Release, @{
  name="Product"
  expression={
      switch -regex ($_.Release) {
        "378389" { [Version]"4.5" }
        "378675|378758" { [Version]"4.5.1" }
        "379893" { [Version]"4.5.2" }
        "393295|393297" { [Version]"4.6" }
        "394254|394271" { [Version]"4.6.1" }
        "394802|394806" { [Version]"4.6.2" }
        "460798|460805" { [Version]"4.7" }
        "461308|461310" { [Version]"4.7.1" }
        "461808|461814" { [Version]"4.7.2" }
        {$_ -gt 461814} { [Version]"Undocumented 4.7.x or higher, please update script" }
      }
    }
}|
Out-File -Append -filePath $FPath

################################################################################
# Get Powershell version installed.
################################################################################
$PSVersionTable.PSVersion |
Out-File -Append -filePath $FPath

################################################################################
# Get Local Groups and Users.
################################################################################
Invoke-Command -ScriptBlock {
[ADSI]$S = "WinNT://$($env:computername)"
$S.children | Where-Object({$_.class -eq 'group'}) |
Select-Object @{Name="Name";Expression={$_.name.value}},
@{Name="Members";Expression={
[ADSI]$group = "$($_.Parent)/$($_.Name),group"
$members = $Group.psbase.Invoke("Members")
($members | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}) -join ";"}
}}|
Select-Object Name,Members |
Out-File -Append -filePath $FPath -width 200