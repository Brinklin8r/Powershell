$User = "BP_Domain\TamPhone"
$PWord = ConvertTo-SecureString -String "TamPS1221" -AsPlainText -Force
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

$OUs = Get-ADOrganizationalUnit -Filter 'Name -like "Staging_Srv*"' -Server DC.Bluepoint.COM |  Select-Object -ExpandProperty DistinguishedName

foreach($OU in $OUs){
    $ComputerName = Get-ADComputer -SearchBase $OU -Filter '*' -Server DC.Bluepoint.COM -Propert Name | Select-Object -ExpandProperty DNSHostName
    if($ComputerName){
        foreach($computer in $ComputerName){
            Invoke-Command -ComputerName $computer -Credential $Cred -ScriptBlock {
                [ADSI]$S = "WinNT://$($env:computername)"
                $S.children.where({$_.class -eq 'group'}) |
                Select-Object @{Name="Name";Expression={$_.name.value}},
                @{Name="Members";Expression={
                [ADSI]$group = "$($_.Parent)/$($_.Name),group"
                $members = $Group.psbase.Invoke("Members")
                ($members | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}) -join ";"}
                }
                } |
                Select-Object PSComputername,Name,Members | 
                Export-Csv -Append -Path "LocalGroupsAndUsers.CSV" -force  
        }
    } 
}

