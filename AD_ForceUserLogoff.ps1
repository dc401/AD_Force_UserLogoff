#20150621 dc Locate a user logged into AD and then log them off
#Enter information as requested. End result is DOMAIN\USER format
#dchow[AT]xtecsystems.com

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

#psuedo secure coding practices 
#Ensure objects are only strings
$domain = Read-Host "Please enter domain".toString()
$userName = Read-Host "Please enter the username to boot.".toString()

#psuedo secure coding practices limiting characters
#https://support.microsoft.com/en-us/kb/909264
If ($domain.length -lt 64 -And $userName.length -lt 16)
{
    #Cat the arguments and call sysinternals to enumerate
    .\PsLoggedon.exe "/accepteula" "$userName" | Select-String -SimpleMatch `
    "$domain\" >> enumhosts.txt 2> $null
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
        .\psshutdown.exe "/accepteula" -o -f "\\$i" 2> "errorhosts.txt"
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