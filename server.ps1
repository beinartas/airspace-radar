$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$port = 8765
$prefix = "http://localhost:$port/"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $root "index.html"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "SYS.AIRSPACE LOCAL SERVER RUNNING AT $prefix" -ForegroundColor Green
Write-Host "Press Ctrl+C or close this window to stop." -ForegroundColor DarkGray

Start-Process $prefix

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response

        try {
            $path = $req.Url.AbsolutePath

            if ($path -eq "/" -or $path -eq "/index.html") {
                $bytes = [System.IO.File]::ReadAllBytes($indexPath)
                $res.ContentType = "text/html; charset=utf-8"
                $res.StatusCode = 200
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            elseif ($path -eq "/countries-50m.json") {
                $mapPath = Join-Path $root "countries-50m.json"
                if (Test-Path $mapPath) {
                    $bytes = [System.IO.File]::ReadAllBytes($mapPath)
                    $res.ContentType = "application/json; charset=utf-8"
                    $res.StatusCode = 200
                    $res.ContentLength64 = $bytes.Length
                    $res.OutputStream.Write($bytes, 0, $bytes.Length)
                } else {
                    $res.StatusCode = 404
                }
            }
            elseif ($path -eq "/api/adsb") {
                $lat = $req.QueryString["lat"]
                $lon = $req.QueryString["lon"]
                $dist = $req.QueryString["dist"]
                $ts = (Get-Date).ToString("HH:mm:ss")
                if (-not $lat -or -not $lon -or -not $dist) {
                    Write-Host "[$ts] 400 /api/adsb missing params" -ForegroundColor Yellow
                    $res.StatusCode = 400
                    $msg = [System.Text.Encoding]::UTF8.GetBytes('{"error":"missing params"}')
                    $res.OutputStream.Write($msg, 0, $msg.Length)
                } else {
                    $url = "https://api.adsb.lol/v2/lat/$lat/lon/$lon/dist/$dist"
                    try {
                        $wc = New-Object System.Net.WebClient
                        $wc.Encoding = [System.Text.Encoding]::UTF8
                        $wc.Headers.Add("User-Agent", "SysAirspaceRadar/1.0")
                        $json = $wc.DownloadString($url)
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $res.ContentType = "application/json; charset=utf-8"
                        $res.Headers.Add("Cache-Control", "no-store")
                        $res.StatusCode = 200
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                        Write-Host "[$ts] 200 $url ($($bytes.Length) bytes)" -ForegroundColor DarkGreen
                    } catch {
                        $errMsg = $_.Exception.Message
                        if ($_.Exception.InnerException) {
                            $errMsg += " | " + $_.Exception.InnerException.Message
                        }
                        Write-Host "[$ts] 502 UPSTREAM ERROR: $url -> $errMsg" -ForegroundColor Red
                        $res.StatusCode = 502
                        $res.ContentType = "application/json; charset=utf-8"
                        $safeErr = ($errMsg -replace '"', '\"' -replace "`r|`n", " ")
                        $errBytes = [System.Text.Encoding]::UTF8.GetBytes("{`"error`":`"$safeErr`"}")
                        $res.OutputStream.Write($errBytes, 0, $errBytes.Length)
                    }
                }
            }
            else {
                $res.StatusCode = 404
            }
        }
        catch {
            $ts = (Get-Date).ToString("HH:mm:ss")
            Write-Host "[$ts] SERVER ERROR: $($_.Exception.Message)" -ForegroundColor Red
            $res.StatusCode = 500
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"server error"}')
            try { $res.OutputStream.Write($errBytes, 0, $errBytes.Length) } catch {}
        }
        finally {
            try { $res.OutputStream.Close() } catch {}
        }
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
