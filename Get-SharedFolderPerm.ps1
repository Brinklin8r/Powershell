# ExportShareInfo.ps1
# This script will export type 0 shares with security info, and provide a hash table of shares
# in which security info could not be found.
#
#reference: http://mow001.blogspot.com/2006/05/powershell-export-shares-and-security.html
#SID was removed from the script. Instead, the username is used to find SID when the import is run
 
# CHANGE TO SERVER THAT HAS SHARES TO EXPORT
# $fileServer = "cbrinkley.bluepoint.com"
 
$date = get-date
$datefile = get-date -uformat '%m-%d-%Y-%H%M%S'
$filename = "Shares.csv"
#Store shares where security cant be found in this hash table
$problemShares = @{}
 
Function Get-AccessMaskDescription($value) {
    $retString = ""    

    if ($value -band 1048576) {
        $retString += "Synchronize, "
    }
    if ($value -band 524288	) {
        $retString += "Write Owner, "
    }
    if ($value -band 262144	) {
        $retString += "Write ACL, "
    }
    if ($value -band 131072	) {
        $retString += "Read Security, "
    }
    if ($value -band 65536	) {
        $retString += "Delete, "
    }
    if ($value -band 256	) {
        $retString += "Write Attr, "
    }
    if ($value -band 128	) {
        $retString += "Read Attr, "
    }
    if ($value -band 64	) {
        $retString += "Delete Dir, "
    }
    if ($value -band 32	) {
        $retString += "Execute, "
    }
    if ($value -band 16	) {
        $retString += "Write ExtAttr, "
    }
    if ($value -band 8	) {
        $retString += "Read ExtAttr, "
    }
    if ($value -band 4	) {
        $retString += "Append, "
    }
    if ($value -band 2	) {
        $retString += "Write, "
    }
    if ($value -band 1	) {
        $retString += "Read."
    }
    return $retString
}

Function Get-AceFlagsDescription($value) {
    $retString = ""    

    if ($value -band 16	) {
        $retString += "Has Been inherited, "
    }
    if ($value -band 8	) {
        $retString += "Not effective will be inherited, "
    }
    if ($value -band 4	) {
        $retString += "Children will not pass on, "
    }
    if ($value -band 2	) {
        $retString += "Containers will inherit and pass on, "
    }
    if ($value -band 1	) {
        $retString += "Non-containers will inherit and pass on"
    }
    if ($retString -eq ""){
        $retString = "Not Inherited"
    }
    return $retString
}
Function Get-ShareInfo($shares) {
    $arrShareInfo = @()
    Foreach ($share in $shares) {
        trap {continue; }
        write-host $share.name
        $strWMI = "\\" + $fileServer + "\root\cimv2:win32_LogicalShareSecuritySetting.Name='" + $share.name + "'"
        $objWMI_ThisShareSec = $null
        $objWMI_ThisShareSec = [wmi]$strWMI
 
        #In case the WMI query or 'GetSecurityDescriptor' fails, we retry a few times before adding to 'problem shares'
        For ($i = 0; ($i -lt 5) -and ($objWMI_ThisShareSec -eq $null); $i++) {
            Start-Sleep -milliseconds 200
            $objWMI_ThisShareSec = [wmi]$strWMI
        }
        $objWMI_SD = $null
        $objWMI_SD = $objWMI_ThisShareSec.invokeMethod('GetSecurityDescriptor', $null, $null)
        For ($j = 0; ($j -lt 5) -and ($objWMI_SD -eq $null); $j++) {
            Start-Sleep -milliseconds 200
            $objWMI_SD = $objWMI_ThisShareSec.invokeMethod('GetSecurityDescriptor', $null, $null)
        }
        If ($objWMI_SD -ne $null) {
            $arrShareInfo += $objWMI_SD.Descriptor.DACL | ForEach-Object {
                $_ | Select-Object @{e = {$share.name}; n = 'Name'},
                @{e = {$share.Path}; n = 'Path'},
                @{e = {$share.Description}; n = 'Description'},
                AccessMask,
                AceFlags,
                AceType,
                @{e = {$_.trustee.Name}; n = 'User'},
                @{e = {$_.trustee.Domain}; n = 'Domain'},
                @{e = {$fileServer}; n = 'Server'}
            }
        }
        Else {
            $ProblemShares.Add($share.name, "failed to find security info")
        }
    }

foreach ($shareItem in $arrshareInfo) {
    $tempResult = Get-AccessMaskDescription($shareItem.AccessMask)
    $shareItem | Add-Member -MemberType NoteProperty -Name "AccessMaskDesc" -Value $tempResult
    $tempResult = Get-AceFlagsDescription($shareItem.AceFlags)
    $shareItem | Add-Member -MemberType NoteProperty -Name "AceFlagsDesc" -Value $tempResult
    if ($shareItem.AceType) {
        $tempResult = "Deny"
    } else {
        $tempResult = "Allow"
    }
    $shareItem | Add-Member -MemberType NoteProperty -Name "AceTypeDesc" -Value $tempResult
}
    return $arrshareInfo
}


$DomainServer = "DC.Bluepoint.COM"
$OUs = Get-ADOrganizationalUnit -Filter "Name -like '*Production*'" -Server $DomainServer |  Select-Object -ExpandProperty DistinguishedName

foreach ($OU in $OUs) {
    $ComputerName = Get-ADComputer -SearchBase $OU -Filter '*' -Server $DomainServer -Property Name | Sort-Object DNSHostname | Select-Object -ExpandProperty DNSHostName 
    if ($ComputerName) {
        foreach ($fileServer in $ComputerName) { 
            Write-Host "Finding Share Security Information $fileServer"
 
            # get Shares (Type 0 is "Normal" shares) # can filter on path, etc. with where
            $shares = Get-WmiObject Win32_Share -ComputerName $fileServer -filter 'type=0'
 
            # get the security info from shares, add the objects to an array
            Write-Host " Complete" -ForegroundColor green
            Write-Host "Preparing Security Info for Export"
 
            $ShareInfo = Get-ShareInfo($shares)
 
            Write-Host " Complete" -ForegroundColor green
            Write-Host "Exporting to CSV"
 
            # Export them to CSV
            $ShareInfo | Select-Object Server, Name, Path, Description, User, Domain, AccessMask, AceFlags, AceType, AccessMaskDesc, AceFlagsDesc, AceTypeDesc | export-csv -noType $filename -Force -Append
 
            Write-Host " Complete" -ForegroundColor green
            Write-Host "Your file $filename has been updated"
            If ($problemShares.count -ge 1) {
                Write-Host "These Shares Failed to Export:"
            }
            $problemShares

        }
    } 
}
