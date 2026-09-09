$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 8080)
$listener.Start()
while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $request = $reader.ReadLine()
    while (($line = $reader.ReadLine()) -ne $null -and $line.Length -gt 0) {}
    $path = if ($request -match '^GET / ') { 'index.html' } else { '' }
    if ($path -and (Test-Path (Join-Path $PSScriptRoot "..\\outputs\\$path"))) {
      $bytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "..\\outputs\\$path"))
      $header = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    } else {
      $bytes = [Text.Encoding]::UTF8.GetBytes('Not found')
      $header = "HTTP/1.1 404 Not Found`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    }
    $headBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($headBytes, 0, $headBytes.Length)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
  } finally { $client.Close() }
}
