# YourDrugs

**YourDrugs** is an iOS application that helps users manage their personal health profile (allergies and chronic conditions), scan medication barcodes, and receive a brief safety analysis using an LLM (Claude via OpenRouter).

## Features

- **Health Profile Management**: Store and update allergies and chronic diseases using Core Data.
- **Barcode Scanning**: Scan EAN-8 and EAN-13 barcodes with AVFoundation to identify medications.
- **Secure API Key Storage**: Input your OpenRouter API key via an in-app alert and save it securely in the iOS Keychain.
- **LLM-Based Safety Analysis**: Analyze medication safety based on user profile with a concise response from Claude.

## Prerequisites

- Xcode 15 or later
- iOS 15.0+ deployment target
- Swift 5.7+

## Dependencies

- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) (via Swift Package Manager)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/opielapatryk/YourDrugs.git
   cd YourDrugs
   ```
2. **Open in Xcode**
   - Double-click `YourDrugs.xcodeproj` or open the folder in Xcode.
3. **Install dependencies**
   - In Xcode, go to **File > Add Packages...** and add `https://github.com/kishikawakatsumi/KeychainAccess`.
4. **Build & Run**
   - Select a simulator or a physical device, then press `Cmd + R`.

## Configuration

1. **Enter your OpenRouter API Key**
   - On the main screen, tap **🔑 Enter API Key**, paste your key, and tap **Save**.
2. **Set up Health Profile**
   - Tap **Update Health data** to add or modify your allergies and chronic conditions.

## Usage

1. **Scan a Medication**
   - Go to **Scan drug**, tap **Scan code**, and point your camera at the barcode.
2. **View Safety Analysis**
   - The app will display a brief: **"Allowed"** or **"Not allowed – <reason>"**, based on your health profile.

## Project Structure

```
YourDrugs/
├── Persistence.swift    # Core Data stack
├── HealthFormView.swift # Form to edit health profile
├── ClaudeAnalyzer.swift # LLM prompt and API integration
├── ContentView.swift
└── YourDrugsApp.swift
```

## Prompt Template

```swift
let prompt = """
    Look up the medication with barcode “\(drugBarcode)” and tell me if it is allowed for human with conditions like \(conditions) and allergies \(allergies).
    Verify if drug with given barcode exists if yes respond with a very brief and strict statement either "Allowed" or "Not allowed" + reason.
    Do NOT mention the barcode, refer only to the medication name.
"""
```

## Contributing

Contributions are welcome! Please submit issues and pull requests on GitHub.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

*2025 © Patryk Opiela*

