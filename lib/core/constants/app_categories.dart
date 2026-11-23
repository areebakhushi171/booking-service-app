import 'package:flutter/material.dart';

/// Service categories shared by the customer panel (browse/filter)
/// and the provider panel (choose a category when uploading a service).
class AppCategories {
  AppCategories._();

  static const List<Map<String, dynamic>> all = [
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

  static String nameOf(String id) => all.firstWhere(
        (c) => c['id'] == id,
        orElse: () => {'name': id},
      )['name'] as String;
}
