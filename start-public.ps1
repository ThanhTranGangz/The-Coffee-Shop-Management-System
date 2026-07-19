# Expose local Tomcat app to the internet via ngrok.
# 1) Create free account: https://dashboard.ngrok.com/signup
# 2) Copy authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
# 3) Run once:
#      .\start-public.ps1 -AuthToken "YOUR_TOKEN"
# 4) Later runs:
#      .\start-public.ps1

param(
    [string]$AuthToken = '',
    [int]$Port = 9999
)

$ErrorActionPreference = 'Stop'
$Ngrok = Join-Path $env:LOCALAPPDATA 'ngrok-latest\ngrok.exe'
if (-not (Test-Path $Ngrok)) {
    $found = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter 'ngrok.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $Ngrok = $found.FullName }
}
if (-not (Test-Path $Ngrok)) { throw 'Chưa cài ngrok. Chạy: winget install Ngrok.Ngrok' }

try {
    $probe = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/The-Coffee-Shop-Management-System-main/" -UseBasicParsing -TimeoutSec 5
    if ($probe.StatusCode -ge 500) { throw "App local lỗi HTTP $($probe.StatusCode)" }
} catch {
    throw "App local chưa chạy ở port $Port. Hãy chạy .\deploy.ps1 hoặc bật Tomcat trước. Chi tiết: $($_.Exception.Message)"
}

if ($AuthToken) {
    & $Ngrok config add-authtoken $AuthToken
    if ($LASTEXITCODE -ne 0) { throw 'Lưu authtoken thất bại.' }
}

Write-Host "Đang mở tunnel public tới http://127.0.0.1:$Port ..."
Write-Host 'Giữ cửa sổ này mở. Link public sẽ hiện bên dưới (Forwarding).'
Write-Host 'URL đầy đủ app:'
Write-Host "  https://<domain-ngrok>/The-Coffee-Shop-Management-System-main/"
Write-Host ''

& $Ngrok http $Port --log=stdout
