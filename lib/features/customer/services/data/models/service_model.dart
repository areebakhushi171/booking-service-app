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

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _parseBool(dynamic value, [bool defaultValue = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _parseDouble(json['price'] ?? json['pricePerNight']),
      durationMinutes: _parseInt(json['durationMinutes'] ?? json['duration'], 60),
      country: (json['country'] ?? 'Pakistan').toString(),
      city: (json['city'] ?? 'Karachi').toString(),
      imageUrl: (json['imageUrl'] ?? (json['images'] is List && (json['images'] as List).isNotEmpty ? json['images'][0] : '')).toString(),
      galleryImages: (json['galleryImages'] ?? json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
