#!/bin/zsh
set -euo pipefail

# ============================================================
# Flashtext Build & Distribution Script
# ============================================================
# Dieses Skript:
# 1. Baut die App im Release-Modus
# 2. Signiert sie mit Developer ID
# 3. Erstellt eine professionelle DMG
# 4. Notarisiert bei Apple
# 5. Stapelt das Notarisation-Ticket
# ============================================================

# Farben für Output
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
DMG_NAME="${APP_NAME}.dmg"
DMG_TEMP="${APP_NAME}-temp.dmg"

# Lade Umgebungsvariablen aus .env
if [[ -f .env ]]; then
    source .env
fi

# Prüfe erforderliche Variablen
if [[ -z "${APPLE_ID:-}" ]] || [[ -z "${APPLE_TEAM_ID:-}" ]] || [[ -z "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo -e "${RED}Fehler: Apple ID Credentials nicht gefunden.${NC}"
    echo "Erstelle eine .env Datei mit:"
    echo "  APPLE_ID=deine.email@example.com"
    echo "  APPLE_TEAM_ID=DEINETEAMID"
    echo "  APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx"
    exit 1
fi

# Finde Developer ID Identity
DEVELOPER_ID=$(security find-identity -p codesigning -v 2>/dev/null | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)".*/\1/')
if [[ -z "$DEVELOPER_ID" ]]; then
    echo -e "${RED}Fehler: Kein Developer ID Application Zertifikat gefunden.${NC}"
    echo "Bitte folge Schritt 1 in BUILD.md"
    exit 1
fi

echo -e "${BLUE}Gefundene Identity: $DEVELOPER_ID${NC}"

# ============================================================
# Schritt 1: Build
# ============================================================
echo -e "\n${YELLOW}=== Schritt 1: Release Build ===${NC}"

# Prüfe ob Swift Package vorhanden
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
# Schritt 2: Code Signing
# ============================================================
echo -e "\n${YELLOW}=== Schritt 2: Code Signing ===${NC}"

# Entitlements prüfen
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

# Signiere die App
echo "Signiere App mit Developer ID..."
codesign --force --options runtime --entitlements "$ENTITLEMENTS" \
    --sign "$DEVELOPER_ID" --deep --verbose \
    "$BUILT_APP"

# Prüfe Signatur
echo "Prüfe Signatur..."
codesign -dvv "$BUILT_APP" 2>&1 | head -5
spctl --assess --type exec --verbose "$BUILT_APP" 2>&1 || true

echo -e "${GREEN}✓ App signiert${NC}"

# ============================================================
# Schritt 3: DMG erstellen
# ============================================================
echo -e "\n${YELLOW}=== Schritt 3: DMG erstellen ===${NC}"

# Erstelle dist Verzeichnis
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME"
rm -f "$DIST_DIR/$DMG_TEMP"

# Erstelle temporäres DMG
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
# Schritt 4: DMG signieren
# ============================================================
echo -e "\n${YELLOW}=== Schritt 4: DMG signieren ===${NC}"

codesign --sign "$DEVELOPER_ID" --verbose "$DIST_DIR/$DMG_NAME"

echo -e "${GREEN}✓ DMG signiert${NC}"

# ============================================================
# Schritt 5: Notarisation
# ============================================================
echo -e "\n${YELLOW}=== Schritt 5: Notarisation ===${NC}"

echo "Reiche DMG zur Notarisation ein..."
NOTARIZE_OUTPUT=$(xcrun notarytool submit "$DIST_DIR/$DMG_NAME" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait 2>&1)

echo "$NOTARIZE_OUTPUT"

# Prüfe ob erfolgreich
if echo "$NOTARIZE_OUTPUT" | grep -q "Accepted"; then
    echo -e "${GREEN}✓ Notarisation akzeptiert${NC}"
else
    echo -e "${RED}✗ Notarisation fehlgeschlagen oder unklar${NC}"
    echo "$NOTARIZE_OUTPUT"
    echo -e "${YELLOW}Versuche trotzdem Stapling...${NC}"
fi

# ============================================================
# Schritt 6: Staple
# ============================================================
echo -e "\n${YELLOW}=== Schritt 6: Staple Ticket ===${NC}"

xcrun stapler staple "$DIST_DIR/$DMG_NAME"

echo -e "${GREEN}✓ Staple erfolgreich${NC}"

# ============================================================
# Schritt 7: Validierung
# ============================================================
echo -e "\n${YELLOW}=== Schritt 7: Validierung ===${NC}"

echo "Prüfe Notarisation..."
spctl -a -t open --context context:primary-signature -v "$DIST_DIR/$DMG_NAME" 2>&1 || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Build erfolgreich!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Datei: $DIST_DIR/$DMG_NAME"
echo "Größe: $(du -h "$DIST_DIR/$DMG_NAME" | cut -f1)"
echo ""
echo "Bereit zum Verteilen!"
