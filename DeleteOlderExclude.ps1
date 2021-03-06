#	set Variables
$chk_path = "\\h-tst-app01.dc.bluepoint.com\Images"
$excl_folder = "DONOTDELETE"	# Nothing in a folder named this will be deleted
$excl_file = "A_NMEDU_MAP.xml","Installation Readme.txt","Import Readme.txt"
$non_empty = "NMEDU","NSFCU","DONOTDELETE"   # Even if empty will not be deleted
$max_days = "90"
 
#	build Variables
$curr_date = Get-Date
$max_days = "-" + $max_days
$excl_path = "*" + $excl_folder + "*"
$del_date = $curr_date.AddDays($max_days)
 
#	delete the files and folders older than $max_days
Get-ChildItem -Path  $chk_path -Recurse -exclude $excl_file | Where { $_.FullName -notlike $excl_path -and $_.LastWriteTime -lt $del_date } | sort length -Descending | Remove-Item -force 
#	The -recurse switch does not work properly on Remove-Item (it will try to 
#	delete folders before all the child items in the folder have been deleted).
#	Sorting the fullnames in descending order by length insures than no folder 
#	is deleted before all the child items in the folder have been deleted.
#	https://stackoverflow.com/questions/14775672/delete-all-files-and-folders-but-exclude-a-directory

#	pause to catch breath
Start-Sleep -s 30

#	delete empty folders that are older than $max_days
Get-ChildItem -Path $chk_path -Directory -Recurse -exclude $non_empty | Where { $_.FullName -notlike $excl_path -and ( Get-ChildItem $_.FullName -Recurse ) -eq $null } | Remove-Item -force 

