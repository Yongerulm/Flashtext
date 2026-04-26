#!/bin/zsh
set -euo pipefail

# ============================================================
# Flashtext Unsigned DMG Build Script
# ============================================================
# Dieses Skript baut eine DMG ohne Apple Developer ID.
# Benutzer muessen die App beim ersten Start mit
# Rechtsklick → Oeffnen bestaetigen (Gatekeeper).
# ============================================================

# Farben fuer Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfiguration
APP_NAME="Flashtext"
BUNDLE_ID="com.flashtext.app"
VERSION="1.0.1"
BUILD_DIR=".build/release"
DIST_DIR="dist"
DMG_NAME="${APP_NAME}-unsigned.dmg"
DMG_TEMP="${APP_NAME}-temp.dmg"

echo -e "${BLUE}Flashtext Unsigned Build${NC}"
echo -e "${YELLOW}Hinweis: Ohne Apple Developer ID muss der Nutzer die App beim ersten Start mit Rechtsklick → Oeffnen bestaetigen.${NC}"
echo ""

# ============================================================
# Schritt 1: Build
# ============================================================
echo -e "${YELLOW}=== Schritt 1: Release Build ===${NC}"

# Pruefe ob Swift Package vorhanden
if [[ ! -f "Package.swift" ]]; then
    echo -e "${RED}Fehler: Package.swift nicht gefunden. Bist du im Projektverzeichnis?${NC}"
    exit 1
fi

# Baue Release-Version
swift build -c release

# Finde das gebaute Binary
BUILT_APP=".build/release/${APP_NAME}.app"
if [[ ! -d "$BUILT_APP" ]]; then
    # Manchmal liegt es in einem anderen Pfad
    BUILT_APP=$(find .build -name "${APP_NAME}.app" -type d | head -1)
fi

if [[ -z "$BUILT_APP" ]] || [[ ! -d "$BUILT_APP" ]]; then
    echo -e "${RED}Fehler: App Bundle nicht gefunden.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App gebaut: $BUILT_APP${NC}"

# ============================================================
# Schritt 2: Ad-hoc Signing (lokale Signatur)
# ============================================================
echo -e "\n${YELLOW}=== Schritt 2: Ad-hoc Signing ===${NC}"

# Entitlements pruefen
ENTITLEMENTS="Flashtext/Resources/${APP_NAME}.entitlements"
if [[ ! -f "$ENTITLEMENTS" ]]; then
    echo -e "${YELLOW}Warnung: Entitlements nicht gefunden, erstelle minimale...${NC}"
    mkdir -p "Flashtext/Resources"
    cat > "$ENTITLEMENTS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.microphone</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
EOF
fi

# Ad-hoc Signatur (kein Developer ID noetig)
echo "Signiere App mit Ad-hoc Signatur..."
codesign --force --sign "-" --entitlements "$ENTITLEMENTS" \
    --deep --verbose \
    "$BUILT_APP"

# Pruefe Signatur
echo "Pruefe Signatur..."
codesign -dvv "$BUILT_APP" 2>&1 | head -5

echo -e "${GREEN}✓ App ad-hoc signiert${NC}"

# ============================================================
# Schritt 3: DMG erstellen
# ============================================================
echo -e "\n${YELLOW}=== Schritt 3: DMG erstellen ===${NC}"

# Erstelle dist Verzeichnis
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME"
rm -f "$DIST_DIR/$DMG_TEMP"

# Erstelle temporaeres DMG
TMP_DIR=$(mktemp -d)
cp -R "$BUILT_APP" "$TMP_DIR/"
ln -s /Applications "$TMP_DIR/Applications"

# Erstelle DMG mit hdiutil
hdiutil create \
    -srcfolder "$TMP_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -format UDRW \
    -size 100m \
    "$DIST_DIR/$DMG_TEMP"

# Mounte zum Anpassen der Fensterposition
MOUNT_DIR=$(hdiutil attach "$DIST_DIR/$DMG_TEMP" -nobrowse -noverify | grep "Apple_HFS" | awk '{print $3}')

if [[ -n "$MOUNT_DIR" ]]; then
    # Setze Fenster-Eigenschaften mit AppleScript
    osascript << EOA
        tell application "Finder"
            tell disk "$APP_NAME"
                open
                set current view of container window to icon view
                set toolbar visible of container window to false
                set statusbar visible of container window to false
                set bounds of container window to {400, 100, 1000, 500}
                set viewOptions to icon view options of container window
                set arrangement of viewOptions to not arranged
                set icon size of viewOptions to 100
                set position of item "$APP_NAME.app" of container window to {150, 200}
                set position of item "Applications" of container window to {450, 200}
                update without registering applications
                delay 2
                close
            end tell
        end tell
EOA

    # Sync und Unmount
    sync
    hdiutil detach "$MOUNT_DIR" -force || true
fi

# Konvertiere zu komprimiertem DMG
hdiutil convert "$DIST_DIR/$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DIST_DIR/$DMG_NAME"

rm -f "$DIST_DIR/$DMG_TEMP"
rm -rf "$TMP_DIR"

echo -e "${GREEN}✓ DMG erstellt: $DIST_DIR/$DMG_NAME${NC}"

# ============================================================
# Fertig
# ============================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Unsigned Build erfolgreich!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Datei: $DIST_DIR/$DMG_NAME"
echo "Groesse: $(du -h "$DIST_DIR/$DMG_NAME" | cut -f1)"
echo ""
echo -e "${YELLOW}WICHTIG:${NC} Da diese DMG nicht mit einer Apple Developer ID signiert ist,"
echo "muessen Benutzer die App beim ersten Start mit Rechtsklick → Oeffnen bestaetigen."
echo ""
echo -e "${BLUE}Fuer eine signierte Version:${NC} ./build-dmg-signed.sh"
echo "(Erfordert Apple Developer Account und Developer ID Zertifikat)"
