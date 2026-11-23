import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookease/app.dart';
import 'package:bookease/core/di/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final providers = await buildAppProviders();

  runApp(
    MultiProvider(
      providers: providers,
      child: const BookEaseApp(),
    ),
  );
}
