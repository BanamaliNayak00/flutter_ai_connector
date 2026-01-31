# Zero AI (AI Assistant Connector)

**Zero AI** is a premium, unified Flutter interface for integrating AI Assistants (OpenAI, Gemini, Groq) into your application with minimal effort. It features a modern "Tech" UI, Lottie animations, Voice Interaction (TTS/STT), and Multi-modal support (Images/Files).

---

## Features

*   **Unified AI Interface**: Switch between OpenAI, Gemini, and Groq providers easily.
*   **Premium UI**: "Zero AI" dark tech theme with gradients, glassmorphism, and polished animations.
*   **Voice Interaction**:
    *   **Speech-to-Text**: Voice input for chatting.
    *   **Text-to-Speech**: Manual playback of AI responses.
*   **Multi-modal Support**: Send images and files (provider dependent).
*   **Lottie Integration**: Visual feedback for AI states (Listening, Thinking, Speaking, Idle).

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  ai_assistant_connector: ^0.0.1
```

## Configuration

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<!-- For TTS visibility on Android 11+ -->
<queries>
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
</queries>
```

### iOS

Add the following keys to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to the microphone for voice commands.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to the camera for image analysis.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to understand your voice commands.</string>
```

---

## Usage

1.  **Initialize Configuration**:
    Create an `AIConfig` object with your API key and preferred settings.

2.  **Add `AIAssistantView`**:
    Place the `AIAssistantView` widget in your app.

```dart
import 'package:flutter/material.dart';
import 'package:ai_assistant_connector/ai_assistant_connector.dart';

class MyChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. Configure
    final config = AIConfig(
      apiKey: 'YOUR_API_KEY',
      provider: AIProvider.groq, // or .openai, .gemini
      modelId: 'llama3-8b-8192', // optional model ID
      systemPrompt: 'You are a helpful AI assistant.',
      isMultimodal: true, // Enable image/file attachments
    );

    return Scaffold(
      appBar: AppBar(title: Text("Zero AI")),
      // 2. Use the View
      body: AIAssistantView(
        config: config,
        // Optional: Provide custom Lottie file path if needed, 
        // otherwise default assets are used.
        // customLottiePath: 'assets/robot.json', 
      ),
    );
  }
}
```

---

## Lottie Assets

The package includes default animations. If you wish to use custom animations, ensure you load them into your project assets and pass the path to `customLottiePath` or replace the assets in the package if forking.

**Default States:**
*   `ai_idle.json`
*   `ai_listening.json`
*   `ai_thinking.json`
*   `ai_speaking.json`

---

## Troubleshooting

*   **Voice Input Fails**: Ensure microphone permissions are granted and you are testing on a real device (simulators may lack mic support).
*   **No Audio Output**: Ensure TTS engine is installed on the device and volume is up.

---

## License

MIT
