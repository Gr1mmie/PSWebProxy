Function Invoke-Connection (
[Parameter(Mandatory=$true)][String]$IP,
[Parameter(Mandatory=$true)][Int32]$Port,
[Parameter(Mandatory=$true)][String]$Data
){
[byte[]]$bytes = [System.Text.Encoding]::ASCII.GetBytes($Data)
$client = New-Object System.Net.Sockets.TcpClient($ip_addr, $port)
$cstrm = $client.GetStream()
$cstrm.Write($bytes,0,$bytes.length)
$cstrm.Flush()
#if ($cstrm){$cstrm.Dispose()}
#if ($client){$client.Dispose()}
}
try{
$ip_addr = '0.0.0.0'
$port = 1080
$svr = new-object System.Net.Sockets.TcpListener($ip_addr, $port)
$svr.start()
write-host "[*] Server started on $ip_addr`:$port" -fore cyan
start-sleep 1
while ($true){
write-host "[*] Awaiting connection..." -fore cyan
while (-not $svr.Pending()){
if ($svr.Pending()){break}
start-sleep 1
}
$conn = $svr.AcceptTcpClient()
if ($conn){
write-host "[*] Connection established" -fore green
$strm = $conn.GetStream()
$read = New-Object System.IO.StreamReader $strm
do{
$line = $read.ReadLine()
write-host $line
if ($traffic){ $traffic = $traffic + "$line`n" }
else {$traffic = "$line`n"}
}while ($line)
#this segment could be repurposed to forward/drop a captured packet
#write-host "[*] Press any key to continue or x to quit"
Write-host "[*] Press f to forward, d to drop, or x to quit"
$ui = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
if ($ui.Character -eq "x"){exit}
if ($ui.Character -eq "d"){
if ($strm){$strm.Dispose()}
if ($read){$read.Dispose()}
if ($conn){$conn.close()}
}
if ($ui.Character -eq "f"){
if ($ip_addr -eq '0.0.0.0'){$ip_addr = '127.0.0.1'}
#open 9080 w/ nc to test
$port = 9080
write-host "[*] Forwarding traffic to $ip_addr`:$port"
Invoke-Connection -IP $ip_addr -Port $port -Data $traffic
}
}
start-sleep 0.5
if ($traffic){Clear-Variable -name traffic}
if ($strm){$strm.Dispose()}
if ($read){$read.Dispose()}
if ($conn){$conn.close()}
}
}
catch [System.Net.Sockets.SocketException]{Write-host "[-] sumthing borked`n[-] svr still open" -fore red}
catch {Write-host "[-] sumthing else borked, not svr this time" -fore red}
finally{
write-host "[*] Closing connection..." -fore cyan
$svr.stop()
}
