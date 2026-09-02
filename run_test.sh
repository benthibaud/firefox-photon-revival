#!/usr/bin/env bash

# ==============================================================================
# SCRIPT DE TEST DU THÈME SOUS XEPHYR
# Usage:
#   ./run_test.sh          -> Lance la variante claire (par défaut)
#   ./run_test.sh light    -> Lance la variante claire
#   ./run_test.sh dark     -> Lance la variante sombre
#   ./run_test.sh crunchy  -> Lance la variante crunchy
# ==============================================================================

MODE="${1:-light}"
BASE_DIR="/home/ben/.gemini/antigravity/scratch/firefox_photon_theme"
TEST_PROF="/tmp/firefox-theme-xephyr"

echo "=== Préparation du profil de test (Mode: $MODE) ==="
rm -rf "$TEST_PROF"
mkdir -p "$TEST_PROF/chrome"

# Copie intégrale des fichiers de configuration, du userChrome et des variantes
cp "$BASE_DIR/user.js" "$TEST_PROF/user.js"
cp "$BASE_DIR/userChrome.css" "$TEST_PROF/chrome/userChrome.css"
if [ -d "$BASE_DIR/variantes" ]; then
  cp -r "$BASE_DIR/variantes" "$TEST_PROF/chrome/"
fi
if [ -d "$BASE_DIR/theme" ]; then
  cp -r "$BASE_DIR/theme" "$TEST_PROF/chrome/"
fi

# Ajustement de l'import de variante dans userChrome.css selon l'argument
if [ "$MODE" = "dark" ]; then
  sed -i 's|^@import "variantes/theme-.*";|/* & */|' "$TEST_PROF/chrome/userChrome.css"
  sed -i 's|.*@import "variantes/theme-sombre.css";.*|@import "variantes/theme-sombre.css";|' "$TEST_PROF/chrome/userChrome.css"
  cat << 'EOF_PREF' >> "$TEST_PROF/user.js"
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
EOF_PREF
elif [ "$MODE" = "crunchy" ]; then
  sed -i 's|^@import "variantes/theme-.*";|/* & */|' "$TEST_PROF/chrome/userChrome.css"
  sed -i 's|.*@import "variantes/theme-crunchy.css";.*|@import "variantes/theme-crunchy.css";|' "$TEST_PROF/chrome/userChrome.css"
  cat << 'EOF_PREF' >> "$TEST_PROF/user.js"
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
EOF_PREF
else
  # Mode clair par défaut
  sed -i 's|^@import "variantes/theme-.*";|/* & */|' "$TEST_PROF/chrome/userChrome.css"
  sed -i 's|.*@import "variantes/theme-clair.css";.*|@import "variantes/theme-clair.css";|' "$TEST_PROF/chrome/userChrome.css"
  cat << 'EOF_PREF' >> "$TEST_PROF/user.js"
user_pref("ui.systemUsesDarkTheme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 1);
EOF_PREF
fi

# Activer les outils de développement internes de Firefox (Browser Toolbox avec Ctrl+Alt+Shift+I)
cat << 'EOF_PREF2' >> "$TEST_PROF/user.js"
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);
user_pref("devtools.debugger.prompt-connection", false);
EOF_PREF2

DISPLAY_NUM=":1"
echo "=== Lancement de Xephyr sur $DISPLAY_NUM ==="
killall Xephyr 2>/dev/null
sleep 0.5

Xephyr $DISPLAY_NUM -ac -screen 1366x768 -resizeable &
XEPHYR_PID=$!
sleep 1.5

echo "=== Lancement de Firefox avec onglets de démonstration ==="
DISPLAY=$DISPLAY_NUM firefox --no-remote --profile "$TEST_PROF" "https://developer.mozilla.org" "https://en.wikipedia.org" &
FF_PID=$!

# Attente de la fermeture de Firefox
wait $FF_PID

echo "=== Arrêt de Xephyr ==="
kill $XEPHYR_PID 2>/dev/null
wait $XEPHYR_PID 2>/dev/null
echo "Test terminé proprement."
