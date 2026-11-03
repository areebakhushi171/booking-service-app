import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookease/main.dart';
import 'package:bookease/providers/theme_provider.dart';
import 'package:bookease/providers/user_provider.dart';
import 'package:bookease/services/storage_service.dart';

void main() {
  testWidgets('BookEaseApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
          ChangeNotifierProvider(create: (_) => UserProvider(storageService)),
        ],
        child: const BookEaseApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

