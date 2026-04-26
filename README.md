# Flashtext

High-performance voice-to-text for macOS. Speak naturally and Flashtext transcribes, processes, and pastes the result directly into any application.

## Table of Contents

1. [Features](#features)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Setup](#setup)
5. [Usage](#usage)
6. [Permissions](#permissions)
7. [Processing Modes](#processing-modes)
8. [Privacy](#privacy)
9. [Development](#development)
10. [Build & Distribution](#build--distribution)
11. [Project Structure](#project-structure)
12. [Technologies](#technologies)
13. [Uninstall](#uninstall)
14. [License](#license)

---

## Features

- **Global Push-to-Talk** — Hold your shortcut anywhere to record
- **AI-Powered Transcription** — OpenAI Whisper for accurate speech-to-text
- **Smart Text Processing** — GPT-4o-mini cleans and formats your text
- **Silent Background Operation** — No windows, no focus stealing
- **One-Click Paste** — Results go straight to your cursor
- **History** — Review and retry past transcriptions

## System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac (Universal Binary)
- Microphone access
- Accessibility permission (for global shortcuts and paste)

## Installation

### For End Users

1. Download `Flashtext.dmg` from the [Releases](https://github.com/Yongerulm/Flashtext/releases) page
2. Open the DMG and drag **Flashtext** to your **Applications** folder
3. Launch Flashtext from Applications
4. Grant **Accessibility** permission when prompted (System Settings > Privacy & Security > Accessibility)
5. Enter your **OpenAI API key** in Settings

For the signed version: The DMG is code-signed and notarized by Apple, so it runs without Gatekeeper warnings.
For the unsigned version: Users must right-click → Open the app on first launch (Gatekeeper warning).

## Setup

1. Click the **waveform icon** in your menu bar
2. Select **Settings...**
3. Paste your **OpenAI API key** (get one at [platform.openai.com](https://platform.openai.com))
4. Optionally set a **language override** if you primarily speak one language
5. Choose your preferred **shortcut** and **processing mode**

## Usage

1. Click into any text field (TextEdit, Mail, Slack, Browser, etc.)
2. Hold **Control + Option + Space**
3. Speak naturally
4. Release the keys
5. Your transcribed and processed text appears at the cursor

### Default Shortcut

- **Control + Option + Space** — Press and hold to record, release to stop

You can change the shortcut in the Settings.

## Permissions

Flashtext requires two system permissions to function:

| Permission | Why it is needed |
|---|---|
| **Accessibility** | To detect global keyboard shortcuts and paste text into other apps |
| **Microphone** | To record your voice for transcription |

## Processing Modes

| Mode | Description |
|---|---|
| **Raw** | Direct Whisper output, no AI processing |
| **Smart** | Cleaned grammar, punctuation, formatting |
| **Professional** | Business-appropriate formal text |
| **Friendly** | Casual, conversational tone |
| **Concise** | Shortened to the essential points |
| **Assertive** | Direct and confident phrasing |

## Privacy

- Your **API key** is stored locally in macOS UserDefaults
- **Audio recordings** are processed in-memory and deleted immediately after transcription
- **No data** is sent anywhere except directly to OpenAI's API

---

## Development

### Prerequisites

- macOS 13.0+
- Xcode 15+ or Swift 5.9+
- [Homebrew](https://brew.sh)

### Clone the Repository

```bash
git clone https://github.com/Yongerulm/Flashtext.git
cd Flashtext
```

### Build

```bash
swift build
```

### Run

```bash
swift run
```

### Open in Xcode

The project includes a pre-generated `.xcodeproj`. You can also regenerate it:

```bash
# Using xcodegen (if installed)
xcodegen generate

# Or open Package.swift directly in Xcode
open Package.swift
```

---

## Build & Distribution

We provide two build options:

### Option A: Unsigned DMG (Quick & Free)

No Apple Developer Account required. Users must right-click → Open on first launch.

```bash
chmod +x build-dmg-unsigned.sh
./build-dmg-unsigned.sh
```

**Output:** `dist/Flashtext-unsigned.dmg`

### Option B: Signed & Notarized DMG (Professional)

Requires Apple Developer Account ($99/year). Runs without Gatekeeper warnings.

#### Prerequisites

- Apple Developer Account
- Developer ID Application certificate
- App-specific password for notarization

#### Step 1: Apple Developer Setup

1. Log in to [developer.apple.com](https://developer.apple.com)
2. Go to **Certificates, IDs & Profiles** → **Certificates**
3. Create a new **Developer ID Application** certificate
4. Download and install the `.cer` file
5. Find your Team ID:
   ```bash
   security find-identity -p codesigning -v
   ```

#### Step 2: App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Generate an app-specific password (e.g., "Flashtext Notarization")
3. Save the password securely (shown only once)

#### Step 3: Configure Environment

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Fill in your credentials:

```
APPLE_ID=your.email@example.com
APPLE_TEAM_ID=YOURTEAMID
APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
```

**Important:** `.env` is already in `.gitignore` and will never be committed.

#### Step 4: Build the Signed DMG

```bash
chmod +x build-dmg-signed.sh
./build-dmg-signed.sh
```

This script will:
1. Build the app in Release mode
2. Code-sign the app with Developer ID and Hardened Runtime
3. Create a professional DMG with app icon and Applications symlink
4. Sign the DMG
5. Submit to Apple for notarization
6. Staple the notarization ticket

**Output:** `dist/Flashtext.dmg`

#### Step 5: Validate

```bash
spctl -a -t open --context context:primary-signature -v dist/Flashtext.dmg
```

Expected output: `accepted`

---

## Project Structure

```
Flashtext/
├── Assets/                         # App icons and iconset
│   ├── Icon.icns
│   └── Icon.iconset/
├── Flashtext/                      # Main source code
│   ├── FlashtextApp.swift         # App entry point
│   ├── Models/                     # Data models
│   │   ├── AppSettings.swift
│   │   ├── ShortcutType.swift
│   │   └── TranscriptionEntry.swift
│   ├── Services/                   # Business logic
│   │   ├── AudioCaptureService.swift
│   │   ├── GlobalPushToTalkService.swift
│   │   ├── LaunchService.swift
│   │   ├── TextInsertionService.swift
│   │   ├── TextProcessingService.swift
│   │   └── WhisperService.swift
│   ├── ViewModels/                 # State management
│   │   └── AppState.swift
│   ├── Views/                      # UI components
│   │   ├── ContentView.swift
│   │   ├── HistoryView.swift
│   │   ├── ModeSelectorView.swift
│   │   ├── ProcessingIndicator.swift
│   │   ├── RecordingView.swift
│   │   ├── ResultView.swift
│   │   └── SettingsView.swift
│   └── Resources/                  # App resources
│       ├── Flashtext.entitlements
│       └── Info.plist
├── .env.example                    # Template for credentials
├── .gitignore                      # Git ignore rules
├── BUILD.md                        # Detailed build instructions
├── Package.swift                   # Swift Package Manager manifest
├── README.md                       # This file
├── build-dmg-signed.sh             # Signed & notarized DMG build
├── build-dmg-unsigned.sh           # Unsigned DMG build (no Apple Dev ID needed)
├── project.yml                     # XcodeGen project configuration
└── setup-project.sh                # Initial project setup script
```

---

## Technologies

- **Swift 5.9**
- **SwiftUI** — Native macOS UI
- **Combine** — Reactive state management
- **OpenAI Whisper API** — Speech-to-text transcription
- **OpenAI GPT-4o-mini API** — Text processing and formatting
- **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** — Global keyboard shortcuts
- **[Sparkle](https://sparkle-project.org/)** — Auto-update framework (prepared)

---

## Uninstall

1. Quit Flashtext
2. Drag `/Applications/Flashtext.app` to Trash
3. Optionally remove settings:
   ```bash
   defaults delete com.flashtext.app
   ```

---

## License

MIT License — free for personal and commercial use.
