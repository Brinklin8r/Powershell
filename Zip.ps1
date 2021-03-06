#$Source    = "C:\temp"
#$Destination = "C:\temp1\temp.zip"
#
#If(Test-path $destination) {
#	Remove-item $destination
#}
#
#Add-Type -assembly "system.io.compression.filesystem"
#[io.compression.zipfile]::CreateFromDirectory($Source, $destination, $compression, $true) 



[Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" )
$src_folder = "c:\temp\" 
$destfile = "c:\temp1\stuff.zip"
$destfile2=[System.IO.Compression.ZipFile]::Open($destfile, "Update")
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
$in = Get-ChildItem $src_folder -Recurse | where {!$_.PsisContainer}| select -expand fullName
[array]$files = $in
ForEach ($file In $files) 
{
        $file2 = $file #whatever you want to call it in the zip
        $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($destfile2,$file,$file2,$compressionlevel)
}
$archiver.Dispose()