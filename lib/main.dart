import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/here_sdk/here_sdk_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HereSdkInitializer.initialize();
  } on HereSdkInitializationException catch (e) {
    runApp(_HereSdkInitFailedApp(message: e.message));
    return;
  }

  await initDependencyInjection();

  runApp(const MyApp());
}

class _HereSdkInitFailedApp extends StatelessWidget {
  final String message;

  const _HereSdkInitFailedApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'HERE SDK failed to initialize',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
