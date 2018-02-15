$sourceDirs = "c:\Program Files\Bluepoint Solutions\", 
    "c:\Program Files (x86)\Bluepoint Solutions\", 
    "c:\inetpub\", 
    "C:\BPAppServer\", 
    "C:\Check\", 
    "E:\BPAppServer\", 
    "E:\Check\"

$targetDir = "c:\Software\Configs\"

foreach ($sourceDir in $sourceDirs ) {
    Get-ChildItem $sourceDir -filter "*.config" -recurse |
        ForEach-Object { 
        $targetFile = $targetDir + $sourceDir.Substring(0,1) + "_" + (Get-Date -Format "yyyyMMdd").ToString() + 
            $sourceDir.Substring(2,$sourceDir.Length-2) + $_.FullName.SubString($sourceDir.Length); 
        New-Item -ItemType File -Path $targetFile -Force;  
        Copy-Item $_.FullName -destination $targetFile 
    } 
}