# Flashtext

High-performance voice-to-text for macOS. Speak naturally and Flashtext transcribes, processes, and pastes the result directly into any application.

## Features

- **Global Push-to-Talk** — Hold your shortcut anywhere to record
- **AI-Powered Transcription** — OpenAI Whisper for accurate speech-to-text
- **Smart Text Processing** — GPT-4o-mini cleans and formats your text
- **Silent Background Operation** — No windows, no focus stealing
- **One-Click Paste** — Results go straight to your cursor
- **History** — Review and retry past transcriptions

## System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- Microphone access
- Accessibility permission (for global shortcuts and paste)

## Installation

1. Download `Flashtext.dmg`
2. Open the DMG and drag **Flashtext** to your **Applications** folder
3. Launch Flashtext from Applications
4. Grant **Accessibility** permission when prompted (System Settings > Privacy & Security > Accessibility)
5. Enter your **OpenAI API key** in Settings

## Default Shortcut

- **Control + Option + Space** — Press and hold to record, release to stop

You can change the shortcut in Settings.

## Permissions

Flashtext requires two system permissions to function:

| Permission | Why it is needed |
|---|---|
| **Accessibility** | To detect global keyboard shortcuts and paste text into other apps |
| **Microphone** | To record your voice for transcription |

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

## Uninstall

1. Quit Flashtext
2. Drag `/Applications/Flashtext.app` to Trash
3. Optionally remove settings: `defaults delete com.flashtext.app`

## License

MIT License — free for personal and commercial use.
