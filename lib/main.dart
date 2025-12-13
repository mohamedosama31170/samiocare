import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:samiocare_app/firebase_options.dart';

import 'samiocare_app.dart';
import 'firebase_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();
  runApp(const SamiocareApp());
}
