import 'dart:convert';

/// Service model representing catalog offerings across Salon, Wellness, Home, Tutoring, Health, Auto
class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price; // Stored in PKR / Rs
  final int durationMinutes;
  final String country;
  final String city;
  final String imageUrl;
  final List<String> galleryImages;
  final List<String> features;
  final bool isPopular;

  /// Owner of the listing. null for the built-in demo catalog.
  final String? providerId;
  final String? providerName;

  /// Hidden from customers when false (provider can pause a listing).
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.country = 'Pakistan',
    this.city = 'Karachi',
    required this.imageUrl,
    this.galleryImages = const [],
    this.features = const [],
    this.isPopular = false,
    this.providerId,
    this.providerName,
    this.isActive = true,
  });

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int _parseDuration(Map<String, dynamic> json) {
    final candidates = [
      json['durationMinutes'],
      json['duration'],
      json['duration_minutes'],
      json['durationInMinutes'],
      json['serviceDuration'],
      json['time'],
    ];

    for (final val in candidates) {
      if (val is num && val > 0) return val.toInt();
      if (val is String && val.trim().isNotEmpty) {
        final parsed = int.tryParse(val.trim());
        if (parsed != null && parsed > 0) return parsed;

        final match = RegExp(r'(\d+)').firstMatch(val.trim());
        if (match != null) {
          final extracted = int.tryParse(match.group(1)!);
          if (extracted != null && extracted > 0) {
            if (val.toLowerCase().contains('hr') || val.toLowerCase().contains('hour')) {
              return extracted * 60;
            }
            return extracted;
          }
        }
      }
    }

    return 60;
  }

  static bool _parseBool(dynamic value, [bool defaultValue = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawImg = json['imageUrl'] ?? json['image'] ?? json['mainImage'] ?? '';
    String imgUrl = '';
    if (rawImg is String) {
      imgUrl = rawImg.trim();
    } else if (rawImg is Map && rawImg['url'] is String) {
      imgUrl = (rawImg['url'] as String).trim();
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      imgUrl = json['images'][0].toString().trim();
    }

    List<String> gallery = [];
    final rawGallery = json['galleryImages'] ??
        json['images'] ??
        json['photos'] ??
        json['gallery'] ??
        json['existingGalleryImages'] ??
        json['imageUrls'];

    if (rawGallery is List) {
      gallery = rawGallery
          .map((e) {
            if (e is String) return e.trim();
            if (e is Map && e['url'] is String) return (e['url'] as String).trim();
            return e.toString().trim();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawGallery is String && rawGallery.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawGallery);
        if (decoded is List) {
          gallery = decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        gallery = rawGallery
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    if (imgUrl.isEmpty && gallery.isNotEmpty) {
      imgUrl = gallery.first;
    }

    return ServiceModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _parseDouble(json['price'] ?? json['pricePerNight']),
      durationMinutes: _parseDuration(json),
      country: (json['country'] ?? 'Pakistan').toString(),
      city: (json['city'] ?? 'Karachi').toString(),
      imageUrl: imgUrl,
      galleryImages: gallery,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPopular: _parseBool(json['isPopular'], false),
      providerId: json['providerId']?.toString() ?? json['ownerId']?.toString(),
      providerName: json['providerName']?.toString() ?? json['owner']?['name']?.toString(),
      isActive: _parseBool(json['isActive'], true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'duration': durationMinutes,
      'durationMinutes': durationMinutes,
      'country': country.isNotEmpty ? country : 'Pakistan',
      'city': city.isNotEmpty ? city : 'Karachi',
      'imageUrl': imageUrl,
      'galleryImages': galleryImages.isNotEmpty ? galleryImages : [imageUrl],
      'features': features,
      'isActive': isActive,
    };
  }

  ServiceModel copyWith({
    String? name,
    String? category,
    String? description,
    double? price,
    int? durationMinutes,
    String? country,
    String? city,
    String? imageUrl,
    List<String>? features,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      country: country ?? this.country,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages,
      features: features ?? this.features,
      isPopular: isPopular,
      providerId: providerId,
      providerName: providerName,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedPrice => 'Rs ${price.toStringAsFixed(0)}';
  String get formattedDuration => '$durationMinutes mins';
}
