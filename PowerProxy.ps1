Function Invoke-Connection{
	
	[Alias("Invoke-Fwd", "Open-Client", "Open-Conn", "Invoke-Conn")]
	
	param(
		# default settings for testing w/ nc
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
		[Parameter(Mandatory=$false)][String]$IP = '0.0.0.0',
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
				if ($tmp -and $ContentLength){
					$line_interval = 0
					while ($interval -le $ContentLength){
						$data_line = $read.Read()
						$full_data  = $full_data + "$data_line "
						$line_interval = $line_interval + 1
						if ($line_interval -eq $ContentLength){ break }
					}
					if ($full_data){
						$ByteArray = $full_data.Split(' ') | ForEach-Object{ [byte]$_ }
						$data = [Text.Encoding]::Ascii.GetString($ByteArray)
						write $data
						}
					break
				}
				else{
					$header_line = $read.ReadLine()
					write $header_line
					if ($header_line -like "Host:*"){
						$host_line = ($header_line -split ": ")[1]
						$recv_ip = ($host_line -split ":")[0]
						$recv_port = ($host_line -split ":")[1]
					}
					if ($host_line -like "Content-Length*"){
						$ContentLength = ($host_line -split ':')[1]
						$ContentLength = [int]$ContentLength
					}
					if ($header){ $header = $header + "$header_line`n"}
					else {$header = "$header_line`n"}
				}
				if ($header_line -eq '' -and -not $tmp -and $ContentLength){ $tmp = "tmp" }
			}while ($header_line -or ($tmp -and $ContentLength))
			Write-host "[*] Press f to forward, d to drop, or x to quit"
			$ui = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
			if ($ui.Character -eq "x"){exit}
			elseif ($ui.Character -eq "d"){
				Write-host "[*] Dropping packet..."
				start-sleep 1
				if ($strm){$strm.Dispose()}
				if ($read){$read.Dispose()}
				if ($conn){$conn.close()}
			}
			elseif ($ui.Character -eq "f"){
				if ($ip_addr -eq '0.0.0.0'){$ip_addr = '127.0.0.1'}
				if ($data){$traffic = $header + $dline}
				else {$traffic = $header}
				Invoke-Connection -Data $traffic
				start-sleep 1
			}
			else{
				write-host "[-] Invalid input detected" -fore red
				exit
			}
		}
		start-sleep 0.5
		if ($traffic){Clear-Variable -name traffic}
		if ($header_line){Clear-Variable -name header_line}
		if ($data_line){Clear-Variable -name data_line}
		if ($tmp){Clear-Variable -name tmp}
		if ($full_data){Clear-Variable -name full_data}
		if ($ByteArray){Clear-Variable -name ByteArray}
		if ($ContentLength){Clear-Variable -name ContentLength}
		if ($line_interval){Clear-Variable -name line_interval}
		if ($host_line){Clear-Variable -name host_line}
		if ($recv_ip){Clear-Variable -name recv_ip}
		if ($recv_port){Clear-Variable -name recv_port}
		if ($header){Clear-Variable -name header}
		if ($tmp){Clear-Variable -name tmp}
		if ($data){Clear-Variable -name data}
		if ($strm){$strm.Dispose()}
		if ($read){$read.Dispose()}
		if ($conn){$conn.close()}
	}
}
catch [System.Net.Sockets.SocketException]{
	Write-host "[-] Sumthing borked`n[-] svr still open" -fore red
	Write-Warning $_.Exception.Message
	}
catch {
	Write-host "[-] Error occured:" -fore red
	Write-Warning $_.Exception.Message
}
finally{
	write-host "[*] Closing connection..." -fore cyan
	$global:svr.stop()
}
