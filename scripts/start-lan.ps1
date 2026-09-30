param(
    [string]$IpAddress,
    [int]$ApiPort = 8000,
    [int]$WebPort = 8080
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Test-PortAvailable {
    param([int]$Port)

    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    return -not ($listeners | Where-Object { $_.Port -eq $Port })
}

function Get-LanIpAddress {
    $client = [System.Net.Sockets.UdpClient]::new()
    try {
        $client.Connect('8.8.8.8', 80)
        return ([System.Net.IPEndPoint]$client.Client.LocalEndPoint).Address.IPAddressToString
    } finally {
        $client.Dispose()
    }
}

if (-not $IpAddress) {
    $IpAddress = Get-LanIpAddress
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw 'Python tidak ditemukan. Instal Python lalu jalankan ulang script ini.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter tidak ditemukan. Pastikan Flutter sudah masuk PATH.'
}
if (-not (Test-PortAvailable $ApiPort)) {
    throw "Port API $ApiPort sedang dipakai. Gunakan -ApiPort dengan port lain."
}
if (-not (Test-PortAvailable $WebPort)) {
    throw "Port web $WebPort sedang dipakai. Gunakan -WebPort dengan port lain."
}

$env:HOST = '0.0.0.0'
$env:PORT = $ApiPort
$apiProcess = Start-Process -FilePath 'python' -ArgumentList @('backend/server.py') -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru

try {
    & flutter build web "--dart-define=API_BASE_URL=http://$IpAddress`:$ApiPort/api/"
    if ($LASTEXITCODE -ne 0) {
        throw 'Build Flutter web gagal.'
    }

    $webProcess = Start-Process -FilePath 'python' -ArgumentList @('-m', 'http.server', $WebPort, '--bind', '0.0.0.0', '--directory', 'build/web') -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru
    $url = "http://$IpAddress`:$WebPort"

    Write-Host ''
    Write-Host "Cakrawala siap dibuka: $url" -ForegroundColor Green
    Write-Host "API: http://$IpAddress`:$ApiPort/api/health"
    Write-Host "Proses API: $($apiProcess.Id), proses web: $($webProcess.Id)"
    Write-Host 'Buka URL di HP/laptop yang tersambung ke Wi-Fi yang sama.'
    Write-Host 'Untuk berhenti: Stop-Process -Id <id-api>, <id-web>'
} catch {
    Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
    throw
}
