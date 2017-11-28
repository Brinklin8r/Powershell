$User = "cbrinkley"
$PWord = ConvertTo-SecureString -String "C@rtman89" -AsPlainText -Force
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
$Servers = @()


$WebServers = 1..254 | 
    ForEach-Object { 
        Get-WmiObject Win32_PingStatus -Filter "Address='10.10.10.$_' and Timeout=20 and StatusCode=0" | 
        Select-Object -ExpandProperty ProtocolAddress 
    }

foreach($ip in $WebServers){
    $Servers += (nslookup $ip h-dc-dc01.dc.bluepoint.com|select-string name|select-object -last 1).toString().split(":")[1].trim()
}



foreach($computer in $Servers){
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