# Mo tunnel ngrok de truy cap app qua internet.
# Lan sau chi can:
#   .\go-public.ps1
# hoac (neu Tomcat da chay):
#   .\start-public.ps1
#
# De giu link KHONG DOI: lay domain mien phi tai
#   https://dashboard.ngrok.com/domains
# roi tao file ngrok.domain (1 dong), vi du:
#   abc123.ngrok-free.app

param(
    [string]$AuthToken = '',
    [string]$Domain = '',
    [int]$Port = 9999
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppPath = '/The-Coffee-Shop-Management-System-main/'
$DomainFile = Join-Path $ProjectRoot 'ngrok.domain'
$UrlFile = Join-Path $ProjectRoot 'public-url.txt'

function Find-Ngrok {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'ngrok-latest\ngrok.exe'),
        (Get-Command ngrok -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    ) | Where-Object { $_ }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    $found = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter 'ngrok.exe' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

function Get-ConfiguredDomain {
    param([string]$Explicit)
    if ($Explicit) { return $Explicit.Trim() }
    if (Test-Path $DomainFile) {
        $line = Get-Content $DomainFile -Raw -ErrorAction SilentlyContinue
        if ($line) {
            $value = ($line -split '\r?\n' | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' } | Select-Object -First 1)
            if ($value) {
                return ($value.Trim() -replace '^https?://', '' -replace '/$', '')
            }
        }
    }
    return ''
}

function Wait-PublicUrl {
    param([int]$TimeoutSec = 25)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $json = Invoke-RestMethod -Uri 'http://127.0.0.1:4040/api/tunnels' -TimeoutSec 2
            $https = $json.tunnels | Where-Object { $_.public_url -like 'https://*' } | Select-Object -First 1
            if ($https) { return $https.public_url.TrimEnd('/') }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    return ''
}

$Ngrok = Find-Ngrok
if (-not $Ngrok) { throw 'Chua cai ngrok. Chay: winget install Ngrok.Ngrok' }

$verText = & $Ngrok version 2>&1 | Out-String
if ($verText -match '(\d+)\.(\d+)\.(\d+)') {
    $major = [int]$Matches[1]; $minor = [int]$Matches[2]
    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 20)) {
        throw "Ngrok qua cu ($($Matches[0])). Chay: ngrok update"
    }
}

try {
    $probe = Invoke-WebRequest -Uri "http://127.0.0.1:$Port$AppPath" -UseBasicParsing -TimeoutSec 5
    if ($probe.StatusCode -ge 500) { throw "App local loi HTTP $($probe.StatusCode)" }
} catch {
    throw "App local chua chay o port $Port. Hay chay .\go-public.ps1 hoac .\deploy.ps1 truoc. Chi tiet: $($_.Exception.Message)"
}

if ($AuthToken) {
    & $Ngrok config add-authtoken $AuthToken
    if ($LASTEXITCODE -ne 0) { throw 'Luu authtoken that bai.' }
}

$useDomain = Get-ConfiguredDomain -Explicit $Domain
Get-Process -Name ngrok -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 400

$ngrokArgs = @('http', "$Port", '--log=stdout')
if ($useDomain) {
    $ngrokArgs += @('--url', $useDomain)
    Write-Host "Dang mo tunnel co dinh: https://$useDomain"
} else {
    Write-Host "Dang mo tunnel ngrok toi http://127.0.0.1:$Port ..."
    Write-Host 'Tip: tao file ngrok.domain de giu link khong doi (xem https://dashboard.ngrok.com/domains).'
}

Write-Host 'Giu cua so nay MO trong luc demo.'
Write-Host ''

$proc = Start-Process -FilePath $Ngrok -ArgumentList $ngrokArgs -PassThru -NoNewWindow
Start-Sleep -Seconds 2

$publicBase = Wait-PublicUrl
if ($publicBase) {
    $appUrl = "$publicBase$AppPath"
    Set-Content -Path $UrlFile -Value $appUrl -Encoding UTF8
    Write-Host '========================================'
    Write-Host ' LINK PUBLIC (copy cai nay):'
    Write-Host " $appUrl"
    Write-Host '========================================'
    Write-Host " Da luu vao: $UrlFile"
    Write-Host " Menu:  ${appUrl}menu.jsp"
    Write-Host " Staff: ${appUrl}staff-login.jsp"
    Write-Host " Admin: ${appUrl}dashboard.jsp"
    Write-Host ' Inspector ngrok: http://127.0.0.1:4040'
    Write-Host '========================================'
    Write-Host ''
} else {
    Write-Host 'Chua lay duoc URL tu ngrok API. Xem dong Forwarding ben duoi.'
}

try {
    Wait-Process -Id $proc.Id
} finally {
    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
