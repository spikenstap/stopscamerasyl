import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [storageProvider.overrideWithValue(LocalStorage(prefs))],
      child: const StopScamApp(),
    ),
  );
}
