# Note de Synthèse & Mémoire Technique — Firefox Photon Revival

> **Dossier local :** `scratch/crunchy-themes/firefox_photon_theme`  
> **Dépôt Git distant :** `https://github.com/benthibaud/firefox-photon-revival.git`  
> **Dernière mise à jour :** 25 Octobre 2026  
> **Statut :** Thème stabilisé, audité et validé sur Firefox moderne (158+)

---

## 1. Contexte & Historique

Adaptation low-tech et frugale de l'ergonomie **Photon** historique pour les versions récentes de Firefox :
* Onglets classiques ultra-compacts (25px) directement connectés à la navbar.
* Angles vifs (radius 2px) sur l'ensemble des composants (boutons, popups, menus déroulants, barres d'outils).
* Moteur CSS centralisé dans `userChrome.css` piloté par une architecture de Design Tokens à deux niveaux (`variantes/variables-clair.css` et `variantes/variables-sombre.css`).

---

## 2. Synthèse des Travaux du 25 Octobre 2026

1. **Banc d'Essai & Qualification (`run_test.sh`) :**
   - Création d'un profil éphémère jetable (`/tmp/firefox-theme-test`) garantissant une isolation totale vis-à-vis du profil personnel.
   - Support de deux modes : mode direct bureau X11 (`DISPLAY=:0`) avec intégration WM native XFCE, et mode conteneur virtuel Xephyr (`--xephyr`).
   - Page d'accueil locale sobre (`demo.html`) avec protection anti-tracking/anti-pub stricte pour un confort de test optimal.
   - Activation automatique de la *Browser Toolbox* (`Ctrl+Alt+Shift+I`) pour le diagnostic XUL en direct.

2. **Résolution des Anomalies Visuelles :**
   - **Bannière de compte Sync FxA (#appMenu-popup) :** Prise en charge des nouveaux sélecteurs Gecko `#appMenu-fxa-sign-in-promo` et `#PanelUI-fxa-menu-sign-in-promo`. Neutralisation du dégradé violet/bleu imposé par Mozilla en mode clair et harmonisation sur une surface sobre sombre uniforme (`rgba(255, 255, 255, 0.05)`), bordure fine, angles 2px et lien d'action vert organique.
   - **Angles Photon sur les Favoris :** Verrouillage strict de `border-radius: var(--general-radius) !important;` (2px) sur `menuitem`, `menu`, les éléments de `#PersonalToolbar` (`.bookmark-item`) et les popups de dossiers de marque-pages, éliminant les arrondis type pilule résiduels de Proton.

3. **Audit Technique (Céline & Jack) :**
   - Parité stricte à 100 % entre `variables-clair.css` et `variables-sombre.css` (137 Design Tokens).
   - 97 variables consommées dans `userChrome.css`, toutes formellement déclarées.
   - Validation complète en conditions réelles par l'utilisateur.

---

## 3. Commandes Clés

* **Tester la variante claire :** `./run_test.sh light`
* **Tester la variante sombre :** `./run_test.sh dark`
* **Installer sur le profil personnel :** `./install.sh`
