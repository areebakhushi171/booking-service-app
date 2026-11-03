/// Review model for service customer feedback
class ReviewModel {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final double rating;
  final String date;
  final String comment;

  const ReviewModel({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.date,
    required this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      rating: (json['rating'] as num).toDouble(),
      date: json['date'] as String,
      comment: json['comment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'rating': rating,
      'date': date,
      'comment': comment,
    };
  }
}
