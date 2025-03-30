# Piece of Sober

A responsible iOS application designed to prevent drunk texting and help users maintain their dignity during nights out. This app implements a unique sobriety verification system before allowing users to send messages to their contacts.

## Features

- 🎮 Sobriety Game Verification: Users must pass a sobriety test before accessing messaging features
- 👥 Contact Management: Rate and manage contacts with different protection levels
- ⏰ Time-Based Protection: Set specific time ranges for enhanced protection
- 🔒 Message Filtering: Prevents potentially regrettable messages during vulnerable times

## Requirements

- iOS 14.0 or later
- Xcode 13.0 or later
- Swift 5.0 or later

## Installation

1. Clone the repository:

```bash
git clone git@github.com:ActsAga/Piece_of_Sober.git
```

2. Open the project in Xcode:

```bash
cd Piece_of_Sober
open "Piece of Sober.xcodeproj"
```

3. Build and run the project in Xcode

## Project Structure

```
├── NoDrunkText/                     # Main application source code
│   ├── ViewController.swift         # Main view controller implementation
│   ├── SobrietyGameViewController.swift  # Sobriety verification game implementation
│   ├── AppDelegate.swift            # Application delegate
│   ├── SceneDelegate.swift          # Scene delegate for UI lifecycle
│   ├── Assets.xcassets/             # App images and assets
│   └── Base.lproj/                  # Base localization files
│
├── NoDrunkTextMessages/             # Messages Extension
│   ├── MessagesViewController.swift # Messages extension main controller
│   ├── Assets.xcassets/             # Extension-specific assets
│   └── Base.lproj/                  # Extension localization files
│
├── NoDrunkTextTests/                # Unit tests directory
├── NoDrunkTextUITests/              # UI tests directory
│
├── ContactManager.swift             # Shared contact management system
├── NoDrunkText.entitlements        # App entitlements file
├── NoDrunkText.plist               # App configuration
└── LICENSE                         # Project license file
```

## License

This project is licensed under the terms of the license included in the [LICENSE](LICENSE) file.
