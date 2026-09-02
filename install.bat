@echo off
chcp 65001 >nul
title Installation Thème Firefox Photon
echo ==========================================================
echo    Installation du Thème Firefox Photon Brut ^& Low-Tech   
echo ==========================================================
echo.
echo PRÉREQUIS IMPORTANT :
echo Assurez-vous que dans Firefox (about:addons ^> Thèmes),
echo le "Thème système — auto" est bien sélectionné.
echo.

set "FF_DIR=%APPDATA%\Mozilla\Firefox"
if not exist "%FF_DIR%\profiles.ini" (
    echo [ERREUR] Impossible de trouver profiles.ini dans %FF_DIR%.
    echo Firefox doit être lancé au moins une fois avant l'installation.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path;" ^
  "if (-not $scriptDir) { $scriptDir = (Get-Location).Path };" ^
  "$ff = [System.IO.Path]::Combine($env:APPDATA, 'Mozilla', 'Firefox');" ^
  "$ini = [System.IO.Path]::Combine($ff, 'profiles.ini');" ^
  "$content = Get-Content $ini;" ^
  "$default = ($content | Where-Object { $_ -match '^Default=(.+)$' } | Select-Object -First 1);" ^
  "if ($default) { $rel = $default.Split('=')[1].Trim() } else {" ^
  "  $pathLine = ($content | Where-Object { $_ -match '^Path=(.+)$' } | Select-Object -First 1);" ^
  "  $rel = $pathLine.Split('=')[1].Trim()" ^
  "};" ^
  "$profilePath = [System.IO.Path]::Combine($ff, $rel.Replace('/', '\'));" ^
  "Write-Host 'Profil détecté :' $profilePath -ForegroundColor Cyan;" ^
  "$chromeDir = [System.IO.Path]::Combine($profilePath, 'chrome');" ^
  "if (!(Test-Path $chromeDir)) { New-Item -ItemType Directory -Path $chromeDir -Force | Out-Null };" ^
  "Copy-Item -Path (Join-Path $scriptDir 'userChrome.css') -Destination $chromeDir -Force;" ^
  "Copy-Item -Path (Join-Path $scriptDir 'variantes') -Destination $chromeDir -Recurse -Force;" ^
  "Write-Host '-> Fichiers userChrome.css et variantes/ copiés.' -ForegroundColor Green;" ^
  "$userJs = [System.IO.Path]::Combine($profilePath, 'user.js');" ^
  "$prefs = @(" ^
  "  'user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);'," ^
  "  'user_pref(\"browser.compactmode.show\", true);'," ^
  "  'user_pref(\"browser.uidensity\", 1);'," ^
  "  'user_pref(\"browser.translations.automaticallyPopup\", false);'" ^
  ");" ^
  "foreach ($p in $prefs) {" ^
  "  Add-Content -Path $userJs -Value $p" ^
  "};" ^
  "Write-Host '-> Préférences configurées dans user.js.' -ForegroundColor Green;" ^
  "Write-Host '' ;" ^
  "Write-Host '==========================================================' -ForegroundColor Yellow;" ^
  "Write-Host '          INSTALLATION TERMINÉE AVEC SUCCÈS !            ' -ForegroundColor Yellow;" ^
  "Write-Host '==========================================================' -ForegroundColor Yellow;" ^
  "Write-Host 'Il ne vous reste plus qu''à relancer Firefox.' -ForegroundColor White;"

echo.
pause
