$ErrorActionPreference = 'Stop'
$src = 'C:\Users\ttt79\reverse\poc_gctune'
$bt = 'C:\Android\sdk\build-tools\34.0.0'
$androidJar = 'C:\Android\sdk\platforms\android-35\android.jar'
$jdk = 'C:\Program Files\Eclipse Adoptium\jdk-11.0.32.9-hotspot\bin'

Push-Location $src
Remove-Item -Recurse -Force classes -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force classes | Out-Null

$srcFiles = @(Get-ChildItem -Path $src -Filter *.java | ForEach-Object { $_.Name })
Write-Output ("compiling: " + ($srcFiles -join ', '))
& "$jdk\javac.exe" -source 1.8 -target 1.8 -nowarn -encoding UTF-8 -bootclasspath $androidJar -cp $androidJar -d classes $srcFiles
if ($LASTEXITCODE -ne 0) { throw "javac failed ($LASTEXITCODE)" }
if (-not (Test-Path 'classes\com\poc\gctune\Main.class')) { throw 'javac failed' }
if (-not (Test-Path 'classes\com\poc\gctune\PrefsActivity.class')) { throw 'javac: PrefsActivity missing' }
if (-not (Test-Path 'classes\com\poc\gctune\SetupActivity.class')) { throw 'javac: SetupActivity missing' }

& "$jdk\jar.exe" cf classes.jar -C classes .
if ($LASTEXITCODE -ne 0) { throw "jar failed ($LASTEXITCODE)" }
& "$bt\d8.bat" --release --lib $androidJar --output . classes.jar
if ($LASTEXITCODE -ne 0) { throw "d8 failed ($LASTEXITCODE)" }
if (-not (Test-Path 'classes.dex')) { throw 'd8 failed' }

Remove-Item gctune-unsigned.apk,gctune-aligned.apk,gctune-signed.apk,gctune-signed.apk.idsig -ErrorAction SilentlyContinue
& "$bt\aapt.exe" package -f -M AndroidManifest.xml -S res -I $androidJar -F gctune-unsigned.apk
if ($LASTEXITCODE -ne 0) { throw "aapt package failed ($LASTEXITCODE)" }
& "$bt\aapt.exe" add gctune-unsigned.apk classes.dex | Out-Null
if ($LASTEXITCODE -ne 0) { throw "aapt add failed ($LASTEXITCODE)" }
& "$bt\zipalign.exe" -f 4 gctune-unsigned.apk gctune-aligned.apk
if ($LASTEXITCODE -ne 0) { throw "zipalign failed ($LASTEXITCODE)" }
& "$bt\apksigner.bat" sign --ks ..\poc_gcrce\poc.keystore --ks-key-alias gd --ks-pass pass:android --key-pass pass:android --out gctune-signed.apk gctune-aligned.apk
if ($LASTEXITCODE -ne 0) { throw "apksigner failed ($LASTEXITCODE)" }
if (-not (Test-Path 'gctune-signed.apk')) { throw 'sign failed' }
Write-Output 'BUILD OK'
Pop-Location
