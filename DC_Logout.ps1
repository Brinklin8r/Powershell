$session	= $null
$username 	= $env:USERNAME

$objDomain = [adsi]'LDAP://dc=dc,dc=bluepoint,dc=Com'
#$objDomain = [adsi]'LDAP://dc=bluepoint,dc=Com'
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = "(&(objectCategory=computer)(name=DC-*))"
#$objSearcher.Filter = "(&(objectCategory=computer)(name=*))"
$objSearcher.PageSize = 1000
$colProplist = "*"
foreach ($i in $colPropList){
	$objSearcher.PropertiesToLoad.Add($i) | out-null
}
$colResults = $objSearcher.FindAll()
$serverlist = @()
foreach ($objResult in $colResults) {
	$serverlist += $objResult.Properties.dnshostname
}   # all Production Server
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = "(&(objectCategory=computer)(name=H-TST-*))"
$objSearcher.PageSize = 1000
foreach ($i in $colPropList){
	$objSearcher.PropertiesToLoad.Add($i) | out-null
}
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults) {
	$serverlist += $objResult.Properties.dnshostname
}   # all Staging Servers.

#Generated Form Function
function GenerateForm {
########################################################################
# Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.9.0
# Generated On: 2/20/2015 3:34 PM
# Generated By: cbrinkley
########################################################################

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$richTextBox1 = New-Object System.Windows.Forms.RichTextBox
$button1 = New-Object System.Windows.Forms.Button
$button2 = New-Object System.Windows.Forms.Button
$button3 = New-Object System.Windows.Forms.Button
$button4 = New-Object System.Windows.Forms.Button
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.
$button1_OnClick= 
{
	$richTextBox1.Text = ''
	$progressBar1.value = 0
	$button1.Enabled = $false
	$button2.Enabled = $false
	$button3.Enabled = $true
	$button4.Enabled = $true

	foreach ($server in $serverlist){
		$richTextBox1.Text = "Checking server: " + $server + "`n" + $richTextBox1.Text
		try {
			$QUResult = quser /server:$server 2>&1
#	http://rcmtech.wordpress.com/2014/04/08/powershell-finding-user-sessions-on-rdsh-servers/
		} catch {
			continue
		}
		$button3.Enabled = $false
		$button4.Enabled = $true
		$session = (($QUResult | ? { $_ -match $username }) -split ' +')[2]
		$progressBar1.value += 1
		Start-Sleep -m 100
		if ($session) {
			$richTextBox1.Text = "Logging " + $username + " off server: " + $server + "`n"  + $richTextBox1.Text
#			logoff $session /server:$server
		}
		$button4.Enabled = $false
		$button3.Enabled = $true
	}
	Start-Sleep -m 500
	$richTextBox1.Text = "Logout Completed`n`n" + $richTextBox1.Text
	$button1.Text = "Re-check Servers"
	$button1.Enabled = $true
	$button2.Enabled = $true
	$button3.Enabled = $false
	$button4.Enabled = $false
}

$button2_OnClick= 
{
	$richTextBox1.Text = "Closing Window`n" 
	$form1.Close()
}

$handler_form1_Load= 
{
	$username 	= $env:USERNAME
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 200
$System_Drawing_Size.Width = 300
$form1.ClientSize = $System_Drawing_Size
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.Text = "Logout of DC"
$form1.add_Load($handler_form1_Load)

$progressBar1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 10
$System_Drawing_Point.Y = 120
$progressBar1.Location = $System_Drawing_Point
$progressBar1.Name = "progressBar1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 25
$System_Drawing_Size.Width = 280
$progressBar1.Size = $System_Drawing_Size
$progressBar1.TabIndex = 2
$progressBar1.Maximum = $serverlist.Count
$progressBar1.Minimum = 0

$form1.Controls.Add($progressBar1)

$richTextBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 10
$System_Drawing_Point.Y = 10
$richTextBox1.Location = $System_Drawing_Point
$richTextBox1.Name = "richTextBox1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 105
$System_Drawing_Size.Width = 280
$richTextBox1.Size = $System_Drawing_Size
$richTextBox1.TabIndex = 3
$richTextBox1.Text = ""

$form1.Controls.Add($richTextBox1)


$button1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 10
$System_Drawing_Point.Y = 150
$button1.Location = $System_Drawing_Point
$button1.Name = "button1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 40
$System_Drawing_Size.Width = 105
$button1.Size = $System_Drawing_Size
$button1.TabIndex = 0
$button1.Text = "Logout"
$button1.UseVisualStyleBackColor = $True
$button1.add_Click($button1_OnClick)

$form1.Controls.Add($button1)

$button2.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 185
$System_Drawing_Point.Y = 150
$button2.Location = $System_Drawing_Point
$button2.Name = "button2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 40
$System_Drawing_Size.Width = 105
$button2.Size = $System_Drawing_Size
$button2.TabIndex = 0
$button2.Text = "DONE"
$button2.UseVisualStyleBackColor = $True
$button2.add_Click($button2_OnClick)
$button2.Enabled = $false

$form1.Controls.Add($button2)

$button3.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 132
$System_Drawing_Point.Y = 170
$button3.Location = $System_Drawing_Point
$button3.Name = "button3"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 39
$button3.Size = $System_Drawing_Size
$button3.TabIndex = 0
$button3.Text = "Brink"
$button3.UseVisualStyleBackColor = $true
$button3.Enabled = $false

$form1.Controls.Add($button3)

$button4.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 132
$System_Drawing_Point.Y = 150
$button4.Location = $System_Drawing_Point
$button4.Name = "button4"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 39
$button4.Size = $System_Drawing_Size
$button4.TabIndex = 0
$button4.Text = "Hail"
$button4.UseVisualStyleBackColor = $true
$button4.Enabled = $false

$form1.Controls.Add($button4)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm
