#20150621 dc Locate a user logged into AD and then log them off
#Enter information as requested. End result is DOMAIN\USER format
#20150710 dc Found a WMI vs RPC VBScript that replaces PSShutdown by Rob van der Woude and added forced EULA accept

Write-Host "==="
Write-Host "This script will attempt to boot interactive users off AD hosts" `
-BackgroundColor Black -ForegroundColor White
Write-Host "==="
Write-Host " "

$testEnum = Test-Path -isvalid .\enumhosts.txt
$testErrors = Test-Path -isvalid .\errorhosts.txt

If ($testEnum -eq $True -And $testErrors -eq $True)
{
    rm .\enumhosts.txt -ErrorAction SilentlyContinue
    rm .\errorhosts.txt -ErrorAction SilentlyContinue
}

#pseudo secure coding practices 
#Ensure objects are only strings
$domain = Read-Host "Please enter domain".toString()
$userName = Read-Host "Please enter the username to boot.".toString()

#pseudo secure coding practices limiting characters
#https://support.microsoft.com/en-us/kb/909264
If ($domain.length -lt 64 -And $userName.length -lt 16)
{
    #Cat the arguments and call sysinternals to enumerate
	regedit /s .\accepteula.reg
    .\PsLoggedon.exe "/accepteula" "$userName" | Select-String -SimpleMatch `
    "$domain\" >> enumhosts.txt 2> $null
    #Powershell v4 and higher for Clear Variable
	Clear-Variable -name null
    Clear
    Write-Host "Enumerating logged on user $domain\$userName" `
    -BackgroundColor Black -ForegroundColor Yellow

    <#
    You may need to stream the file in case there is a ton of entries
    You don't want this loading into entire memory for large env
    This is true if you are trying to do a force logoff for svc accounts

    $hostFile = New-Object System.IO.StreamReader(".\enumhosts.txt")
    while ($line = $hostFile.ReadLine() )
    {
    #foo
    }

    #>

    $hostsArr = Get-Content .\enumhosts.txt | %{ $_.Split(' ')[3]; } | Sort-Object -Unique

    ForEach ($i in $hostsArr)
    {
        cscript .\WMIRemoteLogOff.vbs $i 2> "errorhosts.txt"
        #Write-Host "Logging off $userName console for: $i"
    }
    
    #Notify results
    Write-Host "Hosts where we found $domain\$userName logged in at: enumhosts.txt" `
    -BackgroundColor Black -ForegroundColor White
    Write-Host "Errors are in errorhosts.txt" `
    -BackgroundColor Black -ForegroundColor White
    Write-Host "==="
    Write-Host "If there are error hosts you need to do manual or forced logoff" `
    -BackgroundColor Black -ForegroundColor Red
    Write-Host "==="
    Write-Host " "

    #Clean up temp files
    #rm .\enumhosts.txt
}