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

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js tidak ditemukan. Instal Node.js lalu jalankan ulang script ini.'
}

function Find-AvailablePort {
    param([int]$StartPort, [int]$EndPort)

    for ($port = $StartPort; $port -le $EndPort; $port++) {
        if (Test-PortAvailable $port) { return $port }
    }
    throw "Tidak ada port kosong antara $StartPort dan $EndPort."
}
if (-not (Test-Path (Join-Path $projectRoot 'backend/node_modules'))) {
    Write-Host 'Memasang dependency backend Node.js...'
    & npm --prefix (Join-Path $projectRoot 'backend') install
    if ($LASTEXITCODE -ne 0) { throw 'Instalasi dependency backend gagal.' }
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter tidak ditemukan. Pastikan Flutter sudah masuk PATH.'
}
if (-not (Test-PortAvailable $ApiPort)) {
    if ($PSBoundParameters.ContainsKey('ApiPort')) {
        throw "Port API $ApiPort sedang dipakai. Pilih nilai -ApiPort lain."
    }
    $ApiPort = Find-AvailablePort 8001 8010
    Write-Host "Port API 8000 sedang dipakai; API akan memakai port $ApiPort."
}
if (-not (Test-PortAvailable $WebPort)) {
    if ($PSBoundParameters.ContainsKey('WebPort')) {
        throw "Port web $WebPort sedang dipakai. Pilih nilai -WebPort lain."
    }
    $WebPort = Find-AvailablePort 8081 8090
    Write-Host "Port web 8080 sedang dipakai; website akan memakai port $WebPort."
}

$env:HOST = '0.0.0.0'
$env:PORT = $ApiPort
$apiProcess = Start-Process -FilePath 'node' -ArgumentList @('backend/node_modules/tsx/dist/cli.mjs', 'backend/server.ts') -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru

try {
    & flutter build web "--dart-define=API_BASE_URL=http://$IpAddress`:$ApiPort/api/"
    if ($LASTEXITCODE -ne 0) {
        throw 'Build Flutter web gagal.'
    }

    $webProcess = Start-Process -FilePath 'node' -ArgumentList @('scripts/serve-web.mjs', $WebPort) -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru
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
