# set folder path 
$dump_path = "\\cbrinkley\Images" 
# set min age of files 
$max_days = "-65"
# get the current date 
$curr_date = Get-Date
# determine how far back we go based on current date 
$del_date = $curr_date.AddDays($max_days) 
# delete the files
Get-ChildItem $dump_path -Recurse | Where-Object { $_.LastWriteTime -lt $del_date } | Remove-Item 
# See more at: https://elderec.org/2012/02/scripting-delete-files-and-folders-older-than-x-days/

# Delete any empty directories left behind after deleting the old files.
Get-ChildItem $dump_path  -Recurse -Force | Where-Object { $_.PSIsContainer -and ( Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }	) -eq $null } | Remove-Item -Force -Recurse