$DigitalTestComputers = @("10.110.20.10",   #Test-Web-SKONE	
                        "10.110.21.10",     #Test-Web-MUTSV	 
                        "10.110.22.10",     #Test-Web-POPA	
                        "10.110.23.10",     #Test-Web-CRNST	
                        "10.110.24.10",     #Test-Web-UKENT	
                        "10.110.25.10",     #Test-Web-WFISH	
                        "10.110.27.10",     #Test-Web-FPART	
                        "10.110.28.10",     #Test-Web-PNEST	
                        "10.110.29.10",     #Test-Web-SPAGE	
                        "10.110.30.10",     #Test-Web-NASAU	
                        "10.110.31.10",     #Test-Web-INTEX	
                        "10.110.32.10",     #Test-Web-WNSTH	
                        "10.110.33.10",     #Test-Web-PSDNA	
                        "10.110.34.10",     #Test-Web-TNORTH	
                        "10.110.35.10",     #Test-Web-CACST	
"end")

$DigitalLiveComputers = @("10.110.20.11",	#Web-SKONE01
                        "10.110.20.12",     #Web-SKONE02
                        "10.110.21.11",	    #Web-MUTSV01
                        "10.110.21.12",	    #Web-MUTSV02
                        "10.110.22.11",	    #Web-POPA01
                        "10.110.22.12",	    #Web-POPA02
                        "10.110.23.11",	    #Web-CRNST01
                        "10.110.23.12",	    #Web-CRNST02
                        "10.110.24.11",	    #Web-UKENT01
                        "10.110.24.12",	    #Web-UKENT02
                        "10.110.25.11",	    #Web-WFISH01
                        "10.110.25.12", 	#Web-WFISH02
                        "10.110.27.11", 	#Web-FPART01
                        "10.110.27.12",	    #Web-FPART02
                        "10.110.28.11",	    #Web-PNEST01
                        "10.110.28.12",	    #Web-PNEST02
                        "10.110.29.11",	    #Web-SPAGE01
                        "10.110.29.12",	    #Web-SPAGE02
                        "10.110.30.11",	    #Web-NASAU01
                        "10.110.30.12",	    #Web-NASAU02
                        "10.110.31.11",	    #Web-INTEX01
                        "10.110.31.12",	    #Web-INTEX02
                        "10.110.32.11",	    #Web-WNSTH01
                        "10.110.32.12",	    #Web-WNSTH02
                        "10.110.33.11",	    #Web-PSDNA01
                        "10.110.33.12",	    #Web-PSDNA02
                        "10.110.34.11",	    #Web-TNORTH01
                        "10.110.34.12",	    #Web-TNORTH02
                        "10.110.35.11",	    #Web-CACST01
                        "10.110.35.12",	    #Web-CACST02
                        "10.110.35.13",	    #Web-CACST03
                        "10.110.35.14",	    #Web-CACST04
"end")

$LFITestComputers = @("10.110.100.100",     #CAT-Web-LFI01
                    "10.110.100.101",       #CAT-Web-LFI02
"end")

$LFILiveComputers = @("10.110.5.151",       #Prod-Web-RDCA01
                    "10.110.5.150",         #Prod-Web-RDUS01
"end")

$ECMLiveComputers = @("10.110.8.10",        #Prod-Web-ECM01
                    "10.110.8.11",          #Prod-Web-ECM02
"end")

$IPLiveComputers = @("10.110.5.10",         #Prod-Web-FP01
                    "10.110.5.12",          #Prod-Web-IPF01
                    "10.110.5.13",          #Prod-Web-LIC01
                    "10.110.5.14",          #Prod-Web-Main01
                    "10.110.5.15",          #Prod-Web-Main02
                    "10.110.5.16",          #Prod-Web-Main03
                    "10.110.5.20",          #Prod-Web-Main21
                    "10.110.5.18",          #Prod-Web-SF01
                    "10.110.5.19",          #Prod-Web-SF02
"end")

$secpasswd = ConvertTo-SecureString "C@rtman8@8" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential (".\chris.brinkley", $secpasswd)






$scriptPath = "c:\Users\Christopher.Brinkley\Desktop\Set-USRSLocal-DigitalTest.ps1"

$RemoteComputers = $DigitalTestComputers + $DigitalLiveComputers 









ForEach ($Computer in $RemoteComputers) {
    Try {
        $Session = New-PSSession -ComputerName $Computer -Credential $mycreds -ErrorAction Stop
        Copy-Item $scriptPath -Destination "C:\Alogent Software" -ToSession $Session 
        # Copy Script
        Invoke-Command -FilePath $scriptPath -ComputerName $Computer -Credential $mycreds -ErrorAction Stop
        # Run Script
        #Copy-Item -Path "C:\Users\chris.brinkley\Desktop\*.txt" -Destination "C:\Brink\Files" -FromSession $Session
        # Get Output file
        Add-Content Completed-Computers.txt $Computer
    }
    Catch {
        Add-Content Unavailable-Computers.txt $Computer
    }
}
Add-Content Completed-Computers.txt $Computer