################################################################################
#
# Query Active Directory for expired and about to expire account passwords, 
#	create an alert email for the user and a report for the administrators.
#
# Online Resources:
# 	https://stackoverflow.com/questions/41674518/powershell-setting-security-protocol-to-tls-1-2
#
# Coded By:
#   Brandon Pierce - Initial
#	Chris Brinkley
#
# Version:
#	1.1.1	- 01/11/2019 -	Update to force TLS 1.2
#                           Update to run in AlogentCloud.Local by default.
#                           Filtered out TEMPLATE and Default Windows accounts. 
#   1.1.0   - 01/10/2019 -  Code cleanup, Function building, Parameterization
#	1.0.0 	- xx/xx/2018 -	Initial Build by Brandon.
#
################################################################################

################################################################################
# Parameter Declarations
################################################################################
[CmdletBinding()]
Param(
    [Parameter()]
        [alias("Domain")]
        [string]$SearchDomain = "DC=alogentcloud,DC=local",
    [Parameter()]
        [alias("Admin","AdminEmail")]
        [string]$global:adminReportAddress = "Cleo@alogent.com",

    [switch]$Test,
    [switch]$Help
)

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
# Forces the use of TLS 1.2 for communication

################################################################################
# Function Declarations
################################################################################
function EmailUser ([object] $User, [int] $DaysLeft = 0 ) {
# Creates the email that is sent to a User if their account is expired (0 days left)
#   or if the account will expire in the next 14 or less days.
    
    $expiredDate = (Get-Date (Get-Date).Date.AddDays($DaysLeft - 1))
    # The -1 on the day count is to take into account the time the password expires
    #   as well as the date.

    $userMessage = "Hello " + $User.("GivenName") + ",</br></br>"
    $userMessage += "Your <b>AlogentCloud</b> domain password "
    if (!$DaysLeft) {
        $userMessage += "has expired.</br></br>"
        $userMessage += "At this time you are unable to log into the SSL-VPN and any of the AlogentCloud.Local servers.</br></br>"    
        $userMessage += "Please contact CloudSupport@Alogent.com to have your account reset.</br></br>"
    } else {
        $userMessage += "will expire in <b>" + $DaysLeft + "</b> days.</br>"
        $userMessage += "Please ensure that you change your <b>AlogentCloud</b> domain password *before* " + $expiredDate.ToShortDateString() + ".</br></br>"
        $userMessage += "If you allow your password to expire you will not be unable to log into the SSL-VPN and any of the AlogentCloud.Local servers.</br></br>"
        $userMessage += "If you are in the HNV or NGA office you can log into any domain joined application server and then perform the <b>CTRL+ALT+END</b> 'Change a password' function.</br>"
        $userMessage += "If you are remote you will need to Log into the SSL-VPN and then log into the server <b>PROD-APP-INF01.AlogentCloud.Local</b>.</br> "
        $userMessage += "Now you can perform the <b>CTRL+ALT+END</b> 'Change a password' function.</br></br>"
    }
    $userMessage += "<font color='red'>This is NOT your <b>Alogent.com</b> password that you use for your Email and Corporate access!</font></br></br>"
    $userMessage += "If you have any questions or concerns, please submit a ticket to CloudSupport@Alogent.com</br></br>"
    $userMessage += "Thank You,</br>AlogentCloud Support"
            
    $msg = new-object Net.Mail.MailMessage
    $msg.To.Add($User.("EmailAddress"))
    $msg.From = $global:msgFrom
    $msg.Subject = "AlogentCloud Domain Password Expiration Notice"   
    $msg.IsBodyHTML = $true
    $msg.Body = $userMessage   

    $smtp = new-object Net.Mail.SmtpClient($global:mailServer)
	$smtp.port = 587	
    $smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($global:mailUN, $global:mailPW); 
    if (!$Test){
    # If we are testing I don't want to spam users.
        $smtp.Send($msg)
    }    
    Remove-Variable msg
    Remove-Variable smtp
    Start-Sleep -Seconds 5
    # Pause so that the Exchange server does not flag as spam    
}

################################################################################
function EmailAdminReport(){
# Creates the email that is sent to the administrator(s) of the domain. 
# This report contains all the account that are expired, are going to expire
#   in the next 14 or less days, are set NEVER to expire and those account that
#   are disabled.

    if ($Test) {
        $todayDateDay = 1
    } else {
        $todayDateDay = (Get-Date).Day
    }

    $theBody = "<style>
    table {
    border-collapse: collapse;
    }

    td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 4px;
    }
    </style>"

    $theBody += "<span style='font-family:verdana;font-size:8pt'>"
    $theBody += "<b>AlogentCloud Domain Password Expirations</b></br>"
    $theBody += $global:expiredCount.ToString() + " users with expired accounts</br>"
    $theBody += $global:expiringSoonCount.ToString() + " accounts expiring within 14 days</br>"
    $theBody += $global:nonExpiringCount.ToString() + " accounts are set to not expire.</br>"
    $theBody += $global:disabledCount.ToString() + " accounts are disabled.</b>"
    $theBody += "<hr>"
    $theBody += "<b><h3>Expired Accounts</h3></b>"
    $theBody += $global:expiredTable
    $theBody += "<hr>"
    $theBody += "<b><h3>Accounts Expiring Within 14 Days</h3></b>"
    $theBody += $global:expiringTable
    if($todayDateDay -eq 1 ) {
    # We are only going to add the None Expiring and Disabled account tables on  
    #   the 1st of the month.
        $theBody += "<hr>"
        $theBody +="<b><h3>Accounts Set to Not Expire</h3></b>"
        $theBody += $global:nonExpiringTable
        $theBody += "<hr>"
        $theBody +="<b><h3>Disabled Accounts</h3></b>"
        $theBody += $global:disabledTable
    }  
    $theBody +="</br></br><hr></br>"
    $theBody +="<b>Where I am:</b> This specific script (Get-PassswordExpirationNotice.PS1) is located on PROD-APP-INF01, which is running as a scheduled task in the Microsoft Task Scheduler (once daily at 8am Eastern Time)."
    $theBody +="</br>"
    
    $msg = new-object Net.Mail.MailMessage
    if ($Test){
        $msg.To.Add("chris.brinkley@alogent.com")
    } else {
        $msg.To.Add($global:adminReportAddress)
    }
    $msg.From = $global:msgFrom
    $msg.Subject = "REPORT: Alogent Cloud Domain Password Expirations"
    $msg.IsBodyHTML = $true
    $msg.Body = $theBody

    $smtp = new-object Net.Mail.SmtpClient($global:mailServer)
	$smtp.port = 587	
	$smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($global:mailUN, $global:mailPW);  
	$smtp.Send($msg)
    
    Remove-Variable msg
    Remove-Variable smtp
}

################################################################################
function HandleExpiredAccounts( [object] $userList ) {
# Created the HTML Table of Expired AD accounts and emails the user that their
#   account is Expired

    $global:expiredTable = "<table>"
    $global:expiredTable += "<tr bgcolor='#f2f2f2'><td>First Name</td>"
    $global:expiredTable += "<td>Last Name</td>"
    $global:expiredTable += "<td>Domain Account</td>"
    $global:expiredTable += "<td>Email Address</td>"
    $global:expiredTable += "<td>Last Password Change</td>"
    $global:expiredTable += "<td>Password Expired On</td></tr>"
    # Table header row built

    ForEach ($expiredUser in $userList) {
        $global:expiredCount++
        $global:expiredTable += "<tr><td>"
        $global:expiredTable += $expiredUser.("GivenName") + "</td><td>"
        $global:expiredTable += $expiredUser.("Surname") + "</td><td>"
        $global:expiredTable += $expiredUser.("UserPrincipalName") + "</td>"
        if (!$expiredUser.("EmailAddress")) {
            $global:expiredTable += "<td bgcolor='ffff00'>MISSING EMAIL IN AD - FIX THIS</td><td>" 
        } else {        
            $global:expiredTable += "<td>" + $expiredUser.("EmailAddress") + "</td><td>" 
        }
		if ($expiredUser.("PasswordLastSet")){
        # If the user has never changed their password this will be NULL
			$tempDate = (Get-Date $expiredUser.("PasswordLastSet")).Date
			$global:expiredTable += $tempDate.ToShortDateString() + "</td><td>"
			$tempDate = $tempDate.Date.AddDays($MaxPwdAge) 
			$global:expiredTable +=  $tempDate.ToShortDateString() + "</td>"
        } else {
			$global:expiredTable += "NULL</td><td>NULL</td>"
		}
        $global:expiredTable += "</tr>"

        if (!$expiredUser.("EmailAddress")) {
        } else {
            EmailUser $expiredUser
        }
    }
    $global:expiredTable += "</table>"
}

################################################################################
function HandleExpiringAccounts([object] $userList) {
# Created the HTML Table of Expiring AD accounts and emails the user that their
#   account is about to expire.

    $global:expiringTable = "<table>"
    $global:expiringTable += "<tr bgcolor='#f2f2f2'><td>First Name</td>"
    $global:expiringTable += "<td>Last Name</td>"
    $global:expiringTable += "<td>Domain Account</td>"
    $global:expiringTable += "<td>Email Address</td>"
    $global:expiringTable += "<td>Last Password Change</td>"
    $global:expiringTable += "<td>Password Expires On</td></tr>"
    # Table header row built

    ForEach ($expiringUser in $userList) {
        $tempDate = (Get-Date $expiringUser.("PasswordLastSet")).Date
        $expiredDate = $tempDate.Date.AddDays($MaxPwdAge)
        $daysLeft = (New-TimeSpan -Start (Get-Date).Date -End $expiredDate).Days
               
        if ($daysLeft -lt 15) {
            $global:expiringSoonCount ++
            $global:expiringTable += "<tr><td>"
            $global:expiringTable += $expiringUser.("GivenName") + "</td><td>"
            $global:expiringTable += $expiringUser.("Surname") + "</td><td>"
            $global:expiringTable += $expiringUser.("UserPrincipalName") + "</td>"
            if (!$expiringUser.("EmailAddress")) {
                $global:expiringTable += "<td bgcolor='ffff00'>MISSING EMAIL IN AD - FIX THIS</td><td>" 
            }
            else {        
                $global:expiringTable += "<td>" + $expiringUser.("EmailAddress") + "</td><td>" 
            }       
            $global:expiringTable +=  $tempDate.ToShortDateString() + "</td><td>"
            $global:expiringTable +=  $expiredDate.ToShortDateString() + "</td></tr>"
            if (!$expiringUser.("EmailAddress")) {
            }
            else {
                EmailUser $expiringUser $daysLeft     
            }       
        }
    }
    $global:expiringTable += "</table>"
}

################################################################################
function HandleNonExpiringAccounts( [object] $userList ) {
# Created the HTML Table of NON Expiring AD accounts

    $global:nonExpiringTable = "<table>"
    $global:nonExpiringTable += "<tr bgcolor='#f2f2f2'><td>First Name</td>"
    $global:nonExpiringTable += "<td>Last Name</td>"
    $global:nonExpiringTable += "<td>Domain Account</td>"
    $global:nonExpiringTable += "<td>Email Address</td>"
    $global:nonExpiringTable += "<td>Last Password Change</td>"
    $global:nonExpiringTable += "<td>Password Expires On</td></tr>"
    # Table header row built

    ForEach ($nonExpiringUser in $userList) {
        $global:nonExpiringCount++
        $global:nonExpiringTable += "<tr><td>"
        $global:nonExpiringTable += $nonExpiringUser.("GivenName") + "</td><td>"
        $global:nonExpiringTable += $nonExpiringUser.("Surname") + "</td><td>"
        $global:nonExpiringTable += $nonExpiringUser.("UserPrincipalName") + "</td>"
        if (!$nonExpiringUser.("EmailAddress")) {
            $global:nonExpiringTable += "<td bgcolor='ffff00'>MISSING EMAIL IN AD - FIX THIS</td><td>" 
        } else {        
            $global:nonExpiringTable += "<td>" + $nonExpiringUser.("EmailAddress") + "</td><td>" 
        }
        if ($nonExpiringUser.("PasswordLastSet")) {
        # If the user has never changed their password this will be NULL
			$tempDate = (Get-Date $nonExpiringUser.("PasswordLastSet")).Date
			$global:nonExpiringTable +=  $tempDate.ToShortDateString() + "</td><td>"
			$tempDate = $tempDate.Date.AddDays($MaxPwdAge) 
			$global:nonExpiringTable +=  $tempDate.ToShortDateString() + "</td>"
        } else {
            $global:nonExpiringTable +=  "NULL</td><td>NULL</td>"
        }
        $global:nonExpiringTable += "</tr>"
    }
    $global:nonExpiringTable += "</table>"
}
    
################################################################################
function HandleDisabledAccounts( [object] $userList ) {
# Created the HTML Table of Disabled AD accounts

    $global:disabledTable = "<table>"
    $global:disabledTable += "<tr bgcolor='#f2f2f2'><td>First Name</td>"
    $global:disabledTable += "<td>Last Name</td>"
    $global:disabledTable += "<td>Domain Account</td>"
    $global:disabledTable += "<td>Email Address</td>"
    $global:disabledTable += "<td>Last Password Change</td>"
    $global:disabledTable += "<td>Password Expires On</td></tr>"
    # Table header row built

    ForEach ($disabledUser in $userList) {
        $global:disabledCount++
        $global:disabledTable += "<tr><td>"
        $global:disabledTable += $disabledUser.("GivenName") + "</td><td>"
        $global:disabledTable += $disabledUser.("Surname") + "</td><td>"
        $global:disabledTable += $disabledUser.("UserPrincipalName") + "</td>"
        if (!$disabledUser.("EmailAddress")) {
            $global:disabledTable += "<td bgcolor='ffff00'>MISSING EMAIL IN AD - FIX THIS</td><td>" 
        } else {        
            $global:disabledTable += "<td>" + $disabledUser.("EmailAddress") + "</td><td>" 
        }
        if ($disabledUser.("PasswordLastSet")) {
            # If the user has never changed their password this will be NULL
            $tempDate = (Get-Date $disabledUser.("PasswordLastSet")).Date
            $global:disabledTable +=  $tempDate.ToShortDateString() + "</td><td>"
			$tempDate = $tempDate.Date.AddDays($MaxPwdAge) 
			$global:disabledTable +=  $tempDate.ToShortDateString() + "</td>"
        } else {
            $global:disabledTable +=  "NULL</td><td>NULL</td>"
        }
        $global:disabledTable += "</tr>"
    }
    $global:disabledTable += "</table>"
}

################################################################################
# Variable Declarations
################################################################################
$global:expiredTable = "<b>0 users with expired accounts.</b></br></br>"
$global:expiredCount = 0
$global:expiringTable = "<b>0 accounts expiring within 14 days.</b>"
$global:expiringSoonCount = 0
$global:nonExpiringTable = "<b>0 accounts are set to not expire.</b>"
$global:nonExpiringCount = 0
$global:disabledTable = "<b>0 accounts are disabled.</b>"
$global:disabledCount = 0

$global:mailUN = "internalemail@alogent.com"
$global:mailPW = "Int3rn@l!"
$global:mailServer = "outlook.office365.com"
$global:msgFrom = "internalemail@alogent.com"

$expiredUserList = New-Object System.Collections.ArrayList
$expiringUserList = New-Object System.Collections.ArrayList
$nonExpiringUserList = New-Object System.Collections.ArrayList
$disabledUserList = New-Object System.Collections.ArrayList

$maxPwdAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days

################################################################################
# Main Program
################################################################################
if ($Help) {
    Write-Host "Hope this Helps ;)"
    Write-Host "====================="
    Write-Host "-Domain      <Optional>  String of the OU Object name to search."
    Write-Host "                         The default value is AlogentCloud.Local"   
    Write-Host "-AdminEmail  <Optional>  Email address to send the Admin report to."
    Write-Host "                         The default value is CLEO@Alogent.COM" 
    Write-Host "-Test        <Optional>  Runs the script in test mode to not spam users.'"
    Write-Host "-Help        <Optional>  This screen!"
    Write-Host " "
    Write-Host " "
    Write-Host "EXAMPLES:"
    Write-Host "1)> Get-PasswordExpirationNotice"
    Write-Host "    Runs Script on the default domain"
    Write-Host "2)> Get-PasswordExpirationNotice.ps1 -Domain ""DC=alogent,DC=com"" -Test"
    Write-Host "    Runs Script against the Alogent.COM domain in Test Mode"
    Write-Host " "
    exit
}

$UserList = Get-ADUser -SearchBase $SearchDomain -Filter * -Properties EmailAddress, PasswordExpired, PasswordLastSet, PasswordNeverExpires

foreach ( $User in $UserList){
    if ($User.("GivenName") -eq "..Template" -or ($null -eq $User.("GivenName") -and $null -eq $User.("Surname") -and $null -eq $User.("UserPrincipalName") ) ){
    # Don't tell us about the Default Windows accounts nor our templates.
    } else {
        if ($User.Enabled -eq $True -and $User.PasswordExpired -eq $True -and $User.PasswordNeverExpires -eq $False){
        # Get domain users that are enabled and expired.
            $expiredUserList.add($User)  | Out-Null
        } elseif ($User.Enabled -eq $True -and $User.PasswordExpired -eq $False -and $User.PasswordNeverExpires -eq $False) {
        # Get domain users that are enabled and *not* expired.
            $expiringUserList.Add($User)  | Out-Null
        } elseif ($User.Enabled -eq $True -and $User.PasswordNeverExpires -eq $true) {
        # Get domain users that are enabled and password never expires.
            $nonExpiringUserList.Add($User)  | Out-Null
        } elseif ($User.Enabled -eq $False) {
        # Get domain users that are disabled.
            $disabledUserList.Add($User)  | Out-Null
        }
    }
}

if ($expiredUserList) {
    $expiredUserList = $expiredUserList | Sort-Object Name
    # Sorting the list to make the report table pretty
    HandleExpiredAccounts $expiredUserList   
}

if ($expiringUserList) {
    $expiringUserList = $expiringUserList | Sort-Object Name
    # Sorting the list to make the report table pretty
    HandleExpiringAccounts $expiringUserList   
}

if ($nonExpiringUserList){
    $nonExpiringUserList = $nonExpiringUserList | Sort-Object Name
    # Sorting the list to make the report table pretty
    HandleNonExpiringAccounts $nonExpiringUserList
}

if ($disabledUserList){
    $disabledUserList = $disabledUserList | Sort-Object Name
    # Sorting the list to make the report table pretty
    HandleDisabledAccounts $disabledUserList
}

EmailAdminReport
