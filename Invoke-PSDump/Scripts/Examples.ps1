
$files = "$PSScriptRoot\Captures"
$skypeIRCPCAP = "$PSScriptRoot\Captures\SkypeIRC.cap"
$teardropPCAP = "$PSScriptRoot\Captures\teardrop.cap"
$nb6startupPCAP = "$PSScriptRoot\Captures\nb6-startup.pcap"

#1.
Invoke-WinDump -File $skypeIRCPCAP -DF $true -Pattern "freenode.net" -Verbose

#2.
Invoke-WinDump -File $teardropPCAP -MF $true

#3.
Invoke-WinDump -File $nb6startupPCAP -TCPFlags "SYN"

#4.
Invoke-WinDump -Files $files -TCPFlags "ACK,PUSH"

