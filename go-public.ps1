# Mot lenh de chay app public sau moi lan mo may:
#   .\go-public.ps1
#
# Script se:
# 1) Deploy/bat Tomcat neu chua chay
# 2) Mo ngrok tunnel
# 3) In link public (va luu vao public-url.txt)

param(
    [string]$Domain = '',
    [switch]$SkipDeploy,
    [int]$Port = 9999
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppPath = '/The-Coffee-Shop-Management-System-main/'
$BaseLocal = "http://127.0.0.1:$Port$AppPath"

Set-Location $ProjectRoot

function Test-AppReady {
    try {
        $res = Invoke-WebRequest -Uri $BaseLocal -UseBasicParsing -TimeoutSec 4
        return ($res.StatusCode -ge 200 -and $res.StatusCode -lt 500)
    } catch {
        return $false
    }
}

Write-Host '==> Kiem tra app local...'
if (-not (Test-AppReady)) {
    if ($SkipDeploy) {
        throw "App chua chay o $BaseLocal. Hay chay .\deploy.ps1 truoc."
    }
    Write-Host '==> App chua san sang. Dang deploy/bat Tomcat...'
    & (Join-Path $ProjectRoot 'deploy.ps1')
    if (-not (Test-AppReady)) {
        throw "Van chua mo duoc $BaseLocal. Kiem tra SQL Server + Tomcat log."
    }
} else {
    Write-Host "==> App local OK: $BaseLocal"
}

Write-Host '==> Mo ngrok...'
$startPublic = Join-Path $ProjectRoot 'start-public.ps1'
if ($Domain) {
    & $startPublic -Port $Port -Domain $Domain
} else {
    & $startPublic -Port $Port
}
