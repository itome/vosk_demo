import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vosk_flutter_plugin/vosk_flutter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vosk Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Vosk Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum ModelState {
  uninitialized,
  loading,
  loaded,
}

class _MyHomePageState extends State<MyHomePage> {
  ModelState state = ModelState.uninitialized;
  bool isRecognizing = false;
  String partial = '';
  String result = '';

  @override
  void initState() {
    super.initState();
    VoskFlutterPlugin.onPartial().listen((event) {
      setState(() {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic> && decoded.containsKey('partial')) {
          partial = decoded['partial'];
        }
      });
    });
    VoskFlutterPlugin.onResult().listen((event) {
      setState(() {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic> && decoded.containsKey('text')) {
          partial = '';
          result += decoded['text'];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vosk Demo'),
        actions: [
          if (state == ModelState.loaded) ...[
            IconButton(
              onPressed: () => setState(() {
                partial = '';
                result = '';
              }),
              icon: const Icon(Icons.refresh),
            ),
            if (isRecognizing) ...[
              IconButton(
                onPressed: () {
                  VoskFlutterPlugin.stop();
                  setState(() => isRecognizing = false);
                },
                icon: const Icon(Icons.pause),
              ),
            ] else ...[
              IconButton(
                onPressed: () {
                  VoskFlutterPlugin.start();
                  setState(() => isRecognizing = true);
                },
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ],
        ],
      ),
      body: Column(
        children: [
          if (state == ModelState.uninitialized) ...[
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  setState(() => state = ModelState.loading);
                  final modelZip = await rootBundle.load(
                    'assets/models/vosk-model-small-ja-0.22.zip',
                  );
                  await VoskFlutterPlugin.initModel(modelZip);
                  setState(() => state = ModelState.loaded);
                },
                child: const Text('モデルを読み込む'),
              ),
            ),
            const Spacer(),
          ],
          if (state == ModelState.loading) ...[
            const Spacer(),
            const Center(child: CircularProgressIndicator()),
            const Spacer(),
          ],
          if (state == ModelState.loaded && isRecognizing) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(text: result),
                        TextSpan(
                          text: partial,
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
