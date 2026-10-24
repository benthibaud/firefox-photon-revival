#!/usr/bin/env bash

# ==============================================================================
# SCRIPT DE QUALIFICATION & TEST DU THÈME FIREFOX PHOTON REVIVAL
# Usage :
#   ./run_test.sh               -> Lance le test direct en mode clair (par défaut)
#   ./run_test.sh light         -> Lance le test direct en mode clair
#   ./run_test.sh dark          -> Lance le test direct en mode sombre
#   ./run_test.sh --xephyr      -> Lance le test dans un conteneur Xephyr isolé (clair)
#   ./run_test.sh --xephyr dark -> Lance le test dans un conteneur Xephyr isolé (sombre)
# ==============================================================================

set -e

USE_XEPHYR=0
MODE="light"

# Analyse des arguments
for arg in "$@"; do
  case "$arg" in
    --xephyr|-x)
      USE_XEPHYR=1
      ;;
    dark|sombre|crunchy)
      MODE="dark"
      ;;
    light|clair)
      MODE="light"
      ;;
    *)
      echo "Option non reconnue : $arg"
      echo "Usage : $0 [--xephyr|-x] [light|dark]"
      exit 1
      ;;
  esac
done

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_PROF="/tmp/firefox-theme-test"

echo "======================================================================"
echo "  Banc d'Essai Firefox Photon Revival"
echo "  Mode visuel : $MODE | Environnement : $([ "$USE_XEPHYR" -eq 1 ] && echo "Xephyr (Serveur X virtuel)" || echo "Bureau direct (Natif X11)")"
echo "======================================================================"

# Préparation du profil temporaire isolé
rm -rf "$TEST_PROF"
mkdir -p "$TEST_PROF/chrome"

# 1. Copie des sources du thème
cp "$BASE_DIR/user.js" "$TEST_PROF/user.js"
cp "$BASE_DIR/userChrome.css" "$TEST_PROF/chrome/userChrome.css"
if [ -d "$BASE_DIR/variantes" ]; then
  cp -r "$BASE_DIR/variantes" "$TEST_PROF/chrome/"
fi

# 2. Configuration de la variante dans userChrome.css
if [ "$MODE" = "dark" ]; then
  sed -i 's|^@import "variantes/variables-.*";|/* & */|' "$TEST_PROF/chrome/userChrome.css"
  sed -i 's|.*@import "variantes/variables-sombre.css";.*|@import "variantes/variables-sombre.css";|' "$TEST_PROF/chrome/userChrome.css"
  cat << 'EOF_PREF' >> "$TEST_PROF/user.js"
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
EOF_PREF
else
  sed -i 's|^@import "variantes/variables-.*";|/* & */|' "$TEST_PROF/chrome/userChrome.css"
  sed -i 's|.*@import "variables-clair.css";.*|@import "variantes/variables-clair.css";|' "$TEST_PROF/chrome/userChrome.css"
  sed -i 's|.*@import "variantes/variables-clair.css";.*|@import "variantes/variables-clair.css";|' "$TEST_PROF/chrome/userChrome.css"
  cat << 'EOF_PREF' >> "$TEST_PROF/user.js"
user_pref("ui.systemUsesDarkTheme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 1);
EOF_PREF
fi

# 3. Préférences de débogage et propreté de navigation (zéro pub, zéro télémétrie)
cat << 'EOF_PREF_DEV' >> "$TEST_PROF/user.js"
// Outils d'inspection internes de Firefox (Browser Toolbox : Ctrl+Alt+Shift+I)
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);
user_pref("devtools.debugger.prompt-connection", false);

// Protection contre le pistage stricte (anti-pub natif)
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("browser.contentblocking.category", "strict");

// Éviter tout parasite au démarrage
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.page", 1);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
EOF_PREF_DEV

# Création d'une page de test locale sobre et légère pour valider les onglets
DEMO_HTML="$TEST_PROF/demo.html"
cat << 'EOF_HTML' > "$DEMO_HTML"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Page de Qualification Photon</title>
<style>
  body { font-family: system-ui, sans-serif; padding: 40px; line-height: 1.6; max-width: 800px; margin: auto; background: #fafafa; color: #222; }
  @media (prefers-color-scheme: dark) { body { background: #1e1e24; color: #f0f0f4; } }
  h1 { border-bottom: 2px solid #35A854; padding-bottom: 8px; font-size: 24px; }
  .box { background: rgba(0,0,0,0.05); padding: 16px; border-radius: 4px; margin: 20px 0; border-left: 4px solid #35A854; }
  code { background: rgba(0,0,0,0.1); padding: 2px 6px; border-radius: 3px; font-size: 13px; }
</style>
</head>
<body>
  <h1>🌿 Qualification Firefox Photon Revival</h1>
  <div class="box">
    <strong>Raccourcis clés d'inspection :</strong>
    <ul>
      <li><code>Ctrl + Alt + Shift + I</code> : Ouvrir la <strong>Browser Toolbox</strong> (inspecteur de l'interface Firefox).</li>
      <li><code>Ctrl + T</code> : Ouvrir un nouvel onglet pour vérifier la hauteur (25px) et l'alignement.</li>
      <li><code>Ctrl + Shift + O</code> : Ouvrir la bibliothèque des marque-pages.</li>
      <li>Clic droit sur l'en-tête pour tester les menus contextuels et popups.</li>
    </ul>
  </div>
  <p>Cette session s'exécute sur un profil éphémère jetable dans <code>/tmp/firefox-theme-test</code> sans toucher à votre profil personnel.</p>
</body>
</html>
EOF_HTML

# 4. Lancement selon l'environnement choisi
if [ "$USE_XEPHYR" -eq 1 ]; then
  DISPLAY_NUM=":1"
  echo "-> Lancement du conteneur Xephyr sur $DISPLAY_NUM..."
  killall Xephyr 2>/dev/null || true
  sleep 0.5
  Xephyr $DISPLAY_NUM -ac -screen 1366x768 -resizeable &
  XEPHYR_PID=$!
  sleep 1.5

  # Démarrage d'un gestionnaire de fenêtres dans Xephyr si disponible pour garantir le focus et les menus
  if command -v xfwm4 >/dev/null 2>&1; then
    DISPLAY=$DISPLAY_NUM xfwm4 &
    WM_PID=$!
  fi

  echo "-> Démarrage de Firefox sous Xephyr..."
  DISPLAY=$DISPLAY_NUM firefox --no-remote -profile "$TEST_PROF" "$DEMO_HTML" "about:support" "about:addons" &
  FF_PID=$!

  wait $FF_PID
  kill $WM_PID 2>/dev/null || true
  kill $XEPHYR_PID 2>/dev/null || true
  echo "Session Xephyr terminée."
else
  echo "-> Démarrage de Firefox sur le bureau principal (:0)..."
  echo "   (Profil isolé, zéro impact sur votre session courante)"
  firefox --no-remote -profile "$TEST_PROF" "$DEMO_HTML" "about:support" "about:addons"
  echo "Session de test terminée."
fi
