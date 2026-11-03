import 'review_model.dart';

/// Service model representing catalog offerings across Salon, Wellness, Home, Tutoring, Health, Auto
class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price; // Stored in PKR / Rs
  final int durationMinutes;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> galleryImages;
  final List<String> features;
  final List<ReviewModel> reviews;
  final bool isPopular;
  final bool isTopRated;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    this.galleryImages = const [],
    this.features = const [],
    this.reviews = const [],
    this.isPopular = false,
    this.isTopRated = false,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      imageUrl: json['imageUrl'] as String,
      galleryImages: (json['galleryImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPopular: json['isPopular'] as bool? ?? false,
      isTopRated: json['isTopRated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'features': features,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'isPopular': isPopular,
      'isTopRated': isTopRated,
    };
  }

  String get formattedPrice => 'Rs ${price.toStringAsFixed(0)}';
  String get formattedDuration => '${durationMinutes} mins';
}
