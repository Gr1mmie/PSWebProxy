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
  if ($bytes){Clear-Variable -name bytes}
  if ($cstrm){$cstrm.Dispose()}
  if ($client){$client.Dispose()}
}

Function Initialize-Server (
  [Parameter(Mandatory=$true)][String]$IP,
  [Parameter(Mandatory=$true)][Int32]$Port
){
  $global:svr = new-object System.Net.Sockets.TcpListener($IP, $Port)
  $global:svr.start()
  write-host "[*] Server started on $IP`:$Port" -fore cyan
}

try{
  $ip_addr = '0.0.0.0'
  $port = 1080
  Initialize-Server -IP $ip_addr -Port $port
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
  	Write-host "[*] Press f to forward, d to drop, or x to quit"
  	$ui = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
  	if ($ui.Character -eq "x"){exit}
  	elseif($ui.Character -eq "d"){
    	Write-host "[*] Dropping packet..."
    	if ($strm){$strm.Dispose()}
    	if ($read){$read.Dispose()}
    	if ($conn){$conn.close()}
  	}
  	elseif($ui.Character -eq "f"){
    	if ($ip_addr -eq '0.0.0.0'){$ip_addr = '127.0.0.1'}
#open 9080 w/ nc to test
			$port = 9080
			write-host "[*] Forwarding traffic to $ip_addr`:$port"
			Invoke-Connection -IP $ip_addr -Port $port -Data $traffic
		}
		else{
			write-host "[-] Invalid input detected" -fore red
			exit
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
catch {
	Write-host "[-] sumthing else borked, not svr this time" -fore red
	Write-Warning $($_.Exception.Message)
}
finally{
	write-host "[*] Closing connection..." -fore cyan
	$global:svr.stop()
}
