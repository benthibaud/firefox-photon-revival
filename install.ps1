# ==============================================================================
# SCRIPT D'INSTALLATION POWERSHELL — THÈME FIREFOX PHOTON (Windows)
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Installation du Thème Firefox Photon Brut & Low-Tech   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PRÉREQUIS IMPORTANT :" -ForegroundColor Yellow
Write-Host "Dans Firefox (about:addons > Thèmes), vérifiez que le"
Write-Host "'Thème système — auto' est bien sélectionné."
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

$ff = [System.IO.Path]::Combine($env:APPDATA, 'Mozilla', 'Firefox')
$ini = [System.IO.Path]::Combine($ff, 'profiles.ini')

if (-not (Test-Path $ini)) {
    Write-Host "[ERREUR] profiles.ini introuvable dans $ff." -ForegroundColor Red
    Write-Host "Veuillez lancer Firefox au moins une fois avant l'installation."
    exit 1
}

$content = Get-Content $ini
$default = ($content | Where-Object { $_ -match '^Default=(.+)$' } | Select-Object -First 1)

if ($default) {
    $rel = $default.Split('=')[1].Trim()
} else {
    $pathLine = ($content | Where-Object { $_ -match '^Path=(.+)$' } | Select-Object -First 1)
    $rel = $pathLine.Split('=')[1].Trim()
}

$profilePath = [System.IO.Path]::Combine($ff, $rel.Replace('/', '\'))
Write-Host "Profil détecté : $profilePath" -ForegroundColor Green

$chromeDir = [System.IO.Path]::Combine($profilePath, 'chrome')
if (-not (Test-Path $chromeDir)) {
    New-Item -ItemType Directory -Path $chromeDir -Force | Out-Null
}

Copy-Item -Path (Join-Path $scriptDir 'userChrome.css') -Destination $chromeDir -Force
Copy-Item -Path (Join-Path $scriptDir 'variantes') -Destination $chromeDir -Recurse -Force
Write-Host "-> Fichiers userChrome.css et variantes/ copiés." -ForegroundColor Green

$userJs = [System.IO.Path]::Combine($profilePath, 'user.js')
$prefs = @(
    'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);',
    'user_pref("browser.compactmode.show", true);',
    'user_pref("browser.uidensity", 1);',
    'user_pref("browser.translations.automaticallyPopup", false);'
)

foreach ($p in $prefs) {
    Add-Content -Path $userJs -Value $p
}
Write-Host "-> Préférences configurées dans user.js." -ForegroundColor Green

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "          INSTALLATION TERMINÉE AVEC SUCCÈS !            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Il ne vous reste plus qu'à relancer Firefox." -ForegroundColor White
