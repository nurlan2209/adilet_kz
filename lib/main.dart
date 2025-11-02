import 'package:flutter/material.dart';
import 'package:adiletkz/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdiletApp.initialize();
  runApp(const AdiletApp());
}
