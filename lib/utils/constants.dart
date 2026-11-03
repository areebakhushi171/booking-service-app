import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'BookEase';
  static const String currencySymbol = 'Rs';
  static const String currencyName = 'PKR';

  // Seed colors per requirement
  static const Color primarySeedColor = Color(0xFF1E5EFF);
  static const Color accentTealColor = Color(0xFF0D9488);
  static const Color surfaceLightColor = Color(0xFFF8FAFC);
  static const Color cardLightColor = Color(0xFFFFFFFF);
  static const Color surfaceDarkColor = Color(0xFF0F172A);
  static const Color cardDarkColor = Color(0xFF1E293B);

  // Time slots offered
  static const List<String> standardSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
  ];

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'salon',
      'name': 'Salon & Hair',
      'icon': Icons.content_cut_rounded,
      'description': 'Haircuts, styling, coloring & beard grooming',
    },
    {
      'id': 'wellness',
      'name': 'Wellness & Spa',
      'icon': Icons.spa_rounded,
      'description': 'Deep tissue massage, aromatherapy & facials',
    },
    {
      'id': 'home',
      'name': 'Home & Repair',
      'icon': Icons.build_rounded,
      'description': 'AC servicing, deep cleaning & electrical repair',
    },
    {
      'id': 'tutoring',
      'name': 'Tutoring',
      'icon': Icons.school_rounded,
      'description': 'O/A-Levels, Math, Coding & Language coaching',
    },
    {
      'id': 'health',
      'name': 'Health & Care',
      'icon': Icons.favorite_rounded,
      'description': 'At-home nursing, physiotherapy & blood sampling',
    },
    {
      'id': 'auto',
      'name': 'Auto Care',
      'icon': Icons.directions_car_rounded,
      'description': 'Car detailing, full maintenance & ceramic coating',
    },
  ];
}
