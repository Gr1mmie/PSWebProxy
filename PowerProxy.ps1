Function Invoke-Connection{
	
	[Alias("Invoke-Fwd", "Open-Client", "Open-Conn", "Invoke-Conn")]
	
	param(
		[Parameter(Mandatory=$false)][String]$IP = "127.0.0.1",
		[Parameter(Mandatory=$false)][Int32]$Port = 9080,
		[Parameter(Mandatory=$true)][String]$Data
	)
	
	write-host "[*] Forwarding traffic to $IP`:$Port"
	[byte[]]$bytes = [System.Text.Encoding]::ASCII.GetBytes($Data)
	$client = New-Object System.Net.Sockets.TcpClient($IP, $Port)
	$cstrm = $client.GetStream()
	$cstrm.Write($bytes,0,$bytes.length)
	$cstrm.Flush()
	if ($bytes){Clear-Variable -name bytes}
	if ($cstrm){$cstrm.Dispose()}
	if ($client){$client.Dispose()}
}

Function Initialize-Server{
	
	[Alias("Start-Server", "Open-Server", "Invoke-ServerOpen")]
	
	param(
		[Parameter(Mandatory=$false)][String]$IP = "0.0.0.0",
		[Parameter(Mandatory=$false)][Int32]$Port = 1080
	)
	
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
			}while ($line -or $line -eq "`r`n")
			Write-host "[*] Press f to forward, d to drop, or x to quit"
			$ui = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
			if ($ui.Character -eq "x"){exit}
			elseif($ui.Character -eq "d"){
				Write-host "[*] Dropping packet..."
				start-sleep 1
				if ($strm){$strm.Dispose()}
				if ($read){$read.Dispose()}
				if ($conn){$conn.close()}
			}
			elseif($ui.Character -eq "f"){
				if ($ip_addr -eq '0.0.0.0'){$ip_addr = '127.0.0.1'}
				#open 9080 w/ nc to test
				#$port = 9080
				Invoke-Connection -IP $ip_addr -Data $traffic
				start-sleep 1
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
	Write-Warning $_.Exception.Message
}
finally{
	write-host "[*] Closing connection..." -fore cyan
	$global:svr.stop()
}
