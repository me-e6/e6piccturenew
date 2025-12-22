import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:e6piccturenew/picctureapp.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // CRITICAL FIX: Configure App Check for Debug Mode
  await FirebaseAppCheck.instance.activate(
    // For Android Debug builds - use debug provider
    androidProvider: AndroidProvider.debug,
    // For iOS Debug builds
    appleProvider: AppleProvider.debug,
  );

  runApp(const PicctureApp());
}
