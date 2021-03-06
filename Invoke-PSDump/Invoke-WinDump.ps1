[CmdletBinding()]
Param(
[Parameter(Mandatory=$false, 
    HelpMessage="Provide path to packet capture (.pcap).")]
	[System.String]$File,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Provide directory path to multiple packet captures (.pcaps).")]
	[System.Object[]]$Files,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Print each packet in ASCII.")]
	[System.Boolean]$ASCII,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Print the link-level header on each dump line.")]
	[System.Boolean]$IncludeLinkLayer,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify interface to listen on.")]
	[System.String]$Interface,

[Parameter(Mandatory=$false, 
    HelpMessage="Print less protocol information so output lines are shorter.")]
	[System.Boolean]$Quiet,
	
[Parameter(Mandatory=$false, 
    HelpMessage="When parsing and printing, produce (slightly more) verbose output.")]
	[System.Boolean]$IncludeDetails,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Provide a pattern to search for in the capture.")]
	[System.String]$Pattern,
	
# ----------------
#  IPv4 Parameters
# ----------------

[Parameter(Mandatory=$false,
    HelpMessage="IP Version.")]
	[System.String]$Version,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify IP header length. Example: '>5'")]
	[System.String]$HeaderLength,

[Parameter(Mandatory=$false, 
    HelpMessage="Example: '0x58'")]
	[System.String]$TOS,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify in decimal. Example: '1378'")]
	[System.String]$TotalLength,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify in decimal. Example: '54112'")]
	[System.String]$Identification,
	
[Parameter(Mandatory=$false, 
    HelpMessage="True or False.")]
	[System.Boolean]$Reserve,
	
[Parameter(Mandatory=$false, 
    HelpMessage="True or False.")]
	[System.Boolean]$DF,

[Parameter(Mandatory=$false, 
    HelpMessage="True or False.")]
	[System.Boolean]$MF,
	
[System.String]$FragmentOffset,

[Parameter(Mandatory=$false, 
    HelpMessage="Specify in decimal. Example: 128; '>61'")]
	[System.String]$TTL,

[Parameter(Mandatory=$false, 
    HelpMessage="Example: ")]
	[System.String]$Protocol,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify checksum. Example: 0x7071")]
	[System.String]$IPChecksum,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify source IP address.")]
	[System.String]$IPSource,
	
[Parameter(Mandatory=$false, 
    HelpMessage="Specify destination IP address.")]
	[System.String]$IPDestination,
	
# ----------------
#  TCP Parameters
# ----------------

[Parameter(Mandatory=$false, 
    HelpMessage="TCP Source Port. Example: 10281.")]
	[System.String]$SrcPort,
	
[Parameter(Mandatory=$false, 
    HelpMessage="TCP Destination Port. Example: 80.")]
	[System.String]$DstPort,
	
[Parameter(Mandatory=$false, 
    HelpMessage="TCP Sequence Number (in hex). Example: 0x6a76449a.")]
	[System.String]$SequenceNumber,
	
[Parameter(Mandatory=$false, 
    HelpMessage="TCP Sequence Number (in hex). Example: 0x9934feae.")]
	[System.String]$AckNumber,

[Parameter(Mandatory=$false, 
    HelpMessage="...")]
	[System.String]$Offset,
	
[Parameter(Mandatory=$false, 
    HelpMessage="...")]
	[System.String]$TCPReserved,
	
[Parameter(Mandatory=$false, 
    HelpMessage="...")]
	[System.String]$TCPFlags,

[Parameter(Mandatory=$false, 
    HelpMessage="TCP Window Size (in decimal). Example: 256.")]
	[System.String]$Window,
	
[Parameter(Mandatory=$false, 
    HelpMessage="TCP Checksum (in hex). Example: 0x3355.")]
	[System.String]$TCPChecksum,
	
[Parameter(Mandatory=$false, 
    HelpMessage="TCP Urgent Pointer.")]
	[System.String]$UrgentPointer,
	
# ----------------
#  UDP Parameters
# ----------------

[Parameter(Mandatory=$false, 
    HelpMessage="UDP Source Port. Example: 54467.")]
	[System.String]$UDPSrcPort,
	
[Parameter(Mandatory=$false, 
    HelpMessage="UDP Source Port. Example: 53.")]
	[System.String]$UDPDstPort,
	
[Parameter(Mandatory=$false, 
    HelpMessage="UDP Length (in decimal). Example: 40.")]
	[System.String]$Length,
	
[Parameter(Mandatory=$false, 
    HelpMessage="UDP Checksum (in hex). Example: 0xecb8.")]
	[System.String]$UDPChecksum,

# ----------------
#  ICMP Parameters
# ----------------

[Parameter(Mandatory=$false, 
    HelpMessage="ICMP Type.")]
	[System.String]$Type,
	
[Parameter(Mandatory=$false, 
    HelpMessage="ICMP Code.")]
	[System.String]$Code,
	
[Parameter(Mandatory=$false, 
    HelpMessage="ICMP Checksum.")]
	[System.String]$ICMPChecksum
)


#  dot source reference to dependent PS1 scripts
. "$PSScriptRoot\Scripts\Create-WinDumpFilter.ps1"
. "$PSScriptRoot\Scripts\Search-Pattern.ps1"
. "$PSScriptRoot\Scripts\Start-PacketJob.ps1"

$Script:windump = "$PSScriptRoot\Tools\WinDump.exe"
$Script:results = ''


#  Initialize a hash table that will be used to capture all 
#  user provided parameters.  Enumerate $PSBoundParameters 
#  and add each to the hash table.
$parameters = @{}
foreach ($param in $PSBoundParameters.GetEnumerator())
{
    $parameters.Add($param.Key,$param.Value)
}

#  Initialize a string variable provide the beginning of the WinDump filter.  This filter will be added to based 
#  on parameter values.
if ($protocol) { $Script:WinDumpFilter = "($protocol) " }
else { $Script:WinDumpFilter = "(ip) " }
$Script:WinDumpOptions = ""

#  Convert the user provided values into the 
#  respective WinDump (BPF) required format.
foreach ($key in $parameters.GetEnumerator())
{
	#  Look for respective paramater values and 
	#  translate the expressions to WinDump syntax
	Create-WinDumpFilter -WinDumpParam $key.Name
}

#  Execute WinDump.exe

#  Check for multiple files
if ($files)
{
	#  Enumerate the files
	$pcaps = Get-ChildItem -Path $files
	foreach ($pcap in $pcaps)
	{
		#  Execute WinDump on each .pcap via PowerShell Jobs
		$file = $pcap.FullName
		Start-PacketJob -pcap $file
	}
	Check-Jobs
}
else
{
    Write-Verbose "$Script:windump -r $File -nt $Script:WinDumpFilter"
	$Script:results = & $Script:windump -r $File -nt $Script:WinDumpFilter 2> $null
}

#  If $pattern exists, execute Search-Packets, if not,
#  display WinDump results
if ($pattern)
{
	Search-Packets -set $Script:results -pattern $pattern
}
else
{
	Write-Output "Writing Results:"
	$Script:results
}
#  End of Function


