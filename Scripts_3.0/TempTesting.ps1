[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$ComputerName = @(),
	
   [Parameter(Mandatory=$True)]
   [string]$FilePath = @(),

   [switch]$Testing
)



if ( $Testing){
	Write-Host "Is Test Time"
	exit
} else {
	Write-Host $ComputerName, $FilePath
}
Write-Host "End"