#!/usr/bin/env bash
# ==============================================================================
# SCRIPT D'INSTALLATION AUTOMATIQUE DU THÈME FIREFOX PHOTON (Linux & macOS)
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "   Installation du Thème Firefox Photon Brut & Low-Tech   "
echo "=========================================================="
echo ""
echo "PRÉREQUIS :"
echo "Assurez-vous que dans Firefox (about:addons > Thèmes),"
echo "le 'Thème système — auto' est bien sélectionné."
echo ""

# 1. Recherche du dossier profiles.ini
POSSIBLE_PATHS=(
  "$HOME/.config/mozilla/firefox"
  "$HOME/.mozilla/firefox"
  "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
  "$HOME/snap/firefox/common/.mozilla/firefox"
  "$HOME/Library/Application Support/Firefox"
)

FF_DIR=""
for p in "${POSSIBLE_PATHS[@]}"; do
  if [ -f "$p/profiles.ini" ]; then
    FF_DIR="$p"
    break
  fi
done

if [ -z "$FF_DIR" ]; then
  echo "Erreur : Impossible de localiser automatiquement votre profil Firefox."
  echo "Veuillez copier manuellement les fichiers dans votre dossier de profil."
  exit 1
fi

echo "Dossier Firefox détecté : $FF_DIR"

# 2. Détection du profil par défaut
PROFILE_REL=""

# Chercher Default= dans la section [Install...]
PROFILE_REL=$(grep -E "^Default=" "$FF_DIR/profiles.ini" | head -n 1 | cut -d'=' -f2 || true)

# Si non trouvé, chercher Path= dans les profils
if [ -z "$PROFILE_REL" ]; then
  PROFILE_REL=$(grep -E "^Path=" "$FF_DIR/profiles.ini" | grep -E "default(-release)?" | head -n 1 | cut -d'=' -f2 || true)
fi

if [ -z "$PROFILE_REL" ]; then
  # Fallback premier Path trouvé
  PROFILE_REL=$(grep -E "^Path=" "$FF_DIR/profiles.ini" | head -n 1 | cut -d'=' -f2 || true)
fi

TARGET_PROFILE="$FF_DIR/$PROFILE_REL"

if [ ! -d "$TARGET_PROFILE" ]; then
  echo "Erreur : Le dossier de profil '$TARGET_PROFILE' est introuvable."
  exit 1
fi

echo "Profil cible : $TARGET_PROFILE"
echo ""

# 3. Création du dossier chrome et copie des fichiers
mkdir -p "$TARGET_PROFILE/chrome"
cp -r "$DIR/userChrome.css" "$TARGET_PROFILE/chrome/"
cp -r "$DIR/variantes" "$TARGET_PROFILE/chrome/"
echo "-> Fichiers userChrome.css et variantes/ copiés dans chrome/."

# 4. Activation des préférences dans user.js
USER_JS="$TARGET_PROFILE/user.js"

add_pref() {
  local pref="$1"
  local val="$2"
  if [ -f "$USER_JS" ] && grep -q "$pref" "$USER_JS"; then
    sed -i -E "s/.*$pref.*/user_pref(\"$pref\", $val);/" "$USER_JS"
  else
    echo "user_pref(\"$pref\", $val);" >> "$USER_JS"
  fi
}

add_pref "toolkit.legacyUserProfileCustomizations.stylesheets" "true"
add_pref "browser.compactmode.show" "true"
add_pref "browser.uidensity" "1"
add_pref "browser.translations.automaticallyPopup" "false"

echo "-> Préférences d'activation ajoutées dans user.js."
echo ""
echo "=========================================================="
echo "           INSTALLATION TERMINÉE AVEC SUCCÈS !            "
echo "=========================================================="
echo "Il ne vous reste plus qu'à lancer (ou relancer) Firefox."
echo "La variante claire est active par défaut."
echo "Pour passer en sombre, éditez $TARGET_PROFILE/chrome/userChrome.css"
echo "=========================================================="
