# Build WAR and deploy to local Apache Tomcat 10.1
$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WarName = 'The-Coffee-Shop-Management-System-main'
$JdkHome = 'C:\Program Files\Java\jdk-17'
$TomcatHome = 'C:\Program Files\Apache Software Foundation\Tomcat 10.1'
$Javac = Join-Path $JdkHome 'bin\javac.exe'
$Jar = Join-Path $JdkHome 'bin\jar.exe'

if (-not (Test-Path $Javac)) { throw "Không tìm thấy javac tại $Javac" }
if (-not (Test-Path $Jar)) { throw "Không tìm thấy jar tại $Jar" }
if (-not (Test-Path $TomcatHome)) { throw "Không tìm thấy Tomcat tại $TomcatHome" }

$BuildDir = Join-Path $ProjectRoot 'build\web'
$ClassesDir = Join-Path $BuildDir 'WEB-INF\classes'
$LibOutDir = Join-Path $BuildDir 'WEB-INF\lib'
$DistDir = Join-Path $ProjectRoot 'dist'
$WarPath = Join-Path $DistDir "$WarName.war"
$WebappsDir = Join-Path $TomcatHome 'webapps'
$DeployedWar = Join-Path $WebappsDir "$WarName.war"
$DeployedDir = Join-Path $WebappsDir $WarName
$ContextXml = Join-Path $TomcatHome "conf\Catalina\localhost\$WarName.xml"
$HttpPort = '9999'
try {
    $connector = Select-String -Path (Join-Path $TomcatHome 'conf\server.xml') -Pattern 'Connector\s+port="(\d+)"\s+protocol="HTTP/1.1"' | Select-Object -First 1
    if ($connector) { $HttpPort = $connector.Matches[0].Groups[1].Value }
} catch {}

Write-Host '==> Cleaning build folders'
if (Test-Path $BuildDir) { Remove-Item $BuildDir -Recurse -Force }
New-Item -ItemType Directory -Path $ClassesDir -Force | Out-Null
New-Item -ItemType Directory -Path $LibOutDir -Force | Out-Null
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

Write-Host '==> Copying web resources'
Copy-Item -Path (Join-Path $ProjectRoot 'web\*') -Destination $BuildDir -Recurse -Force

Write-Host '==> Copying libraries'
Copy-Item -Path (Join-Path $ProjectRoot 'lib\*.jar') -Destination $LibOutDir -Force

# Copy Tomcat compile-only APIs into a space-free folder so javac classpath works on Windows.
$CompileLibDir = Join-Path $ProjectRoot 'build\compile-lib'
if (Test-Path $CompileLibDir) { Remove-Item $CompileLibDir -Recurse -Force }
New-Item -ItemType Directory -Path $CompileLibDir -Force | Out-Null
@(
    'servlet-api.jar',
    'jsp-api.jar',
    'websocket-api.jar',
    'websocket-client-api.jar',
    'annotations-api.jar'
) | ForEach-Object {
    $src = Join-Path $TomcatHome "lib\$_"
    if (Test-Path $src) { Copy-Item $src (Join-Path $CompileLibDir $_) -Force }
}

$ClasspathEntries = @()
$ClasspathEntries += Get-ChildItem (Join-Path $CompileLibDir '*.jar') | ForEach-Object { $_.FullName }
$ClasspathEntries += Get-ChildItem (Join-Path $ProjectRoot 'lib\*.jar') | ForEach-Object { $_.FullName }
$Classpath = ($ClasspathEntries | ForEach-Object { $_.Replace('\', '/') }) -join ';'

Write-Host '==> Compiling Java sources'
$Sources = Get-ChildItem (Join-Path $ProjectRoot 'src\java') -Recurse -Filter '*.java' | ForEach-Object { $_.FullName.Replace('\', '/') }
$ArgsFile = Join-Path $ProjectRoot 'build\javac-args.txt'
$argsLines = @(
    '-encoding', 'UTF-8',
    '-source', '17',
    '-target', '17',
    '-classpath', $Classpath,
    '-d', $ClassesDir.Replace('\', '/')
) + $Sources
Set-Content -Path $ArgsFile -Value $argsLines -Encoding ASCII

& $Javac "@$ArgsFile"
if ($LASTEXITCODE -ne 0) { throw 'Compile failed' }

# Copy non-Java resources under src/java (e.g. db.properties) if any
Get-ChildItem (Join-Path $ProjectRoot 'src\java') -Recurse -File |
    Where-Object { $_.Extension -notin '.java' } |
    ForEach-Object {
        $rel = $_.FullName.Substring((Join-Path $ProjectRoot 'src\java').Length).TrimStart('\')
        $dest = Join-Path $ClassesDir $rel
        $destParent = Split-Path $dest -Parent
        if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
        Copy-Item $_.FullName $dest -Force
    }

Write-Host '==> Packaging WAR'
if (Test-Path $WarPath) { Remove-Item $WarPath -Force }
Push-Location $BuildDir
try {
    & $Jar -cf $WarPath *
    if ($LASTEXITCODE -ne 0) { throw 'WAR packaging failed' }
} finally {
    Pop-Location
}

Write-Host "==> WAR created: $WarPath"

# Keep NetBeans-style context pointing at exploded build\web (preferred for this machine).
$contextBody = @"
<?xml version="1.0" encoding="UTF-8"?>
<Context docBase="$($BuildDir.Replace('\','/'))" path="/$WarName"/>
"@
try {
    $contextDir = Split-Path $ContextXml -Parent
    if (-not (Test-Path $contextDir)) { New-Item -ItemType Directory -Path $contextDir -Force | Out-Null }
    Set-Content -Path $ContextXml -Value $contextBody -Encoding UTF8
    Write-Host "==> Updated context: $ContextXml"
} catch {
    Write-Host "==> Không ghi được context XML (cần quyền Admin). Dùng build\web nếu context sẵn có."
}

Write-Host '==> Deploying WAR copy to Tomcat webapps (backup)'
try {
    if (Test-Path $DeployedDir) { Remove-Item $DeployedDir -Recurse -Force }
    Copy-Item $WarPath $DeployedWar -Force
} catch {
    Write-Host '==> Bỏ qua copy WAR vào Program Files (thiếu quyền).'
}

$env:JAVA_HOME = $JdkHome
$env:CATALINA_HOME = $TomcatHome
$env:CATALINA_BASE = $TomcatHome

$javaRunning = Get-Process -Name java -ErrorAction SilentlyContinue
if (-not $javaRunning) {
    Write-Host '==> Starting Tomcat (catalina.bat start)'
    & cmd /c "`"$TomcatHome\bin\catalina.bat`" start"
    Start-Sleep -Seconds 8
} else {
    Write-Host '==> Tomcat/Java already running - reload by touching context or restart manually if needed'
}

Write-Host '==> Waiting for app...'
$ready = $false
$baseUrl = "http://127.0.0.1:$HttpPort/$WarName/"
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    try {
        $res = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec 3
        if ($res.StatusCode -ge 200 -and $res.StatusCode -lt 500) {
            $ready = $true
            break
        }
    } catch {}
}

if ($ready) {
    Write-Host ''
    Write-Host 'Deploy thành công.'
    Write-Host "URL: $baseUrl"
    Write-Host "Menu: http://127.0.0.1:$HttpPort/$WarName/menu.jsp"
    Write-Host "Staff: http://127.0.0.1:$HttpPort/$WarName/staff-login.jsp"
    Write-Host "Admin: http://127.0.0.1:$HttpPort/$WarName/dashboard.jsp (PIN 8888)"
} else {
    Write-Host ''
    Write-Host 'Build xong nhưng app chưa phản hồi. Thử:'
    Write-Host "  1) Mở PowerShell Admin rồi chạy: Start-Service Tomcat10"
    Write-Host "  2) Hoặc: `"$TomcatHome\bin\catalina.bat`" start"
    Write-Host "  3) Mở: $baseUrl"
    Write-Host "Log: $TomcatHome\logs"
}
