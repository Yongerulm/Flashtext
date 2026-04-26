# Build & Distribution Guide

Diese Anleitung beschreibt, wie du Flashtext als signierte und notarisierte DMG verpackst, die sofort nach dem Download funktioniert.

## Voraussetzungen

- Apple Developer Account ($99/Jahr)
- macOS mit Xcode Command Line Tools
- Homebrew

## Schritt 1: Apple Developer ID Zertifikat erstellen

1. Melde dich bei [developer.apple.com](https://developer.apple.com) an
2. Gehe zu **Certificates, IDs & Profiles** → **Certificates**
3. Klicke auf **+** um ein neues Zertifikat zu erstellen
4. Wähle **Developer ID Application**
5. Lade den Certificate Signing Request (CSR) hoch oder erstelle einen neuen:
   ```bash
   # Im Terminal:
   openssl req -new -newkey rsa:2048 -nodes -keyout Flashtext.key -out Flashtext.csr -subj "/emailAddress=deine@email.com, CN=Flashtext Developer, C=DE"
   ```
6. Lade das erstellte Zertifikat (.cer) herunter
7. Doppelklicke auf die .cer Datei, um sie zum Keychain hinzuzufügen
8. Finde deine Team ID:
   ```bash
   security find-identity -p codesigning -v
   ```
   Suche nach: `Developer ID Application: Dein Name (TEAM_ID)`

## Schritt 2: App-spezifisches Passwort erstellen

1. Gehe zu [appleid.apple.com](https://appleid.apple.com)
2. Melde dich mit deiner Apple ID an
3. Gehe zu **App-Specific Passwords**
4. Klicke auf **Generate an app-specific password**
5. Gib einen Namen ein (z.B. "Flashtext Notarization")
6. Speichere das generierte Passwort sicher ab (du siehst es nur einmal!)

## Schritt 3: Umgebungsvariablen setzen

Erstelle eine `.env` Datei im Projektverzeichnis:

```bash
# .env
APPLE_ID=deine.email@example.com
APPLE_TEAM_ID=DEINETEAMID
APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
```

**Wichtig:** Füge `.env` zu deiner `.gitignore` hinzu!

## Schritt 4: Build-Skript ausführen

```bash
chmod +x build-dmg.sh
./build-dmg.sh
```

Das Skript führt automatisch aus:
1. App bauen (Release-Build)
2. App mit Developer ID signieren
3. DMG mit professionellem Layout erstellen
4. DMG bei Apple notarisieren
5. Notarisation stapeln (staple)

## Schritt 5: Ergebnis testen

Die fertige DMG liegt in `dist/Flashtext.dmg`.

Teste die Notarisation:
```bash
spctl -a -t open --context context:primary-signature -v dist/Flashtext.dmg
```

Erwartete Ausgabe: `accepted`

## Fehlerbehebung

### "No identity found"
- Prüfe mit `security find-identity -p codesigning -v`
- Stelle sicher, dass das Developer ID Application-Zertifikat im Login-Keychain ist

### Notarisation schlägt fehl
- Prüfe den Apple ID Notarization History: `xcrun notarytool history --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD"`
- Details zu einem spezifischen Job: `xcrun notarytool log <SUBMISSION_ID> ...`

### Gatekeeper blockiert trotzdem
- Prüfe: `codesign -dvv dist/Flashtext.app`
- Prüfe Staple: `xcrun stapler staple -v dist/Flashtext.dmg`
