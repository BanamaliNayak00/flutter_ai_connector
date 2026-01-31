import 'package:ai_assistant_connector/ai_assistant_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // DEVELOPER: Configure your AI settings here
    final config = AIConfig(
      apiKey: dotenv.env['GROQ_API_KEY'] ?? '',
      provider: AIProvider.groq,
      isMultimodal: true,
      systemPrompt: 'You are a lively Assistant.',
      modelId: 'qwen/qwen3-32b', // User specified model
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zero AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFF000000,
        ), // Pure Black for seamless look
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: ChatScreen(config: config),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final AIConfig config;

  const ChatScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zero AI"), centerTitle: true),
      extendBodyBehindAppBar: true,
      body: AIAssistantView(
        config: config,
        // customLottiePath: 'assets/robot.json',
      ),
    );
  }
}
