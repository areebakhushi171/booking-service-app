/// Default cover photos per category, used when a provider does not paste
/// their own image link. Real image upload arrives with the backend
/// (multipart POST /uploads) and will replace the link field.
class ServiceImagePresets {
  ServiceImagePresets._();

  static const Map<String, String> byCategory = {
    'salon':
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80',
    'wellness':
        'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&w=800&q=80',
    'home':
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80',
    'tutoring':
        'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=800&q=80',
    'health':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
    'auto':
        'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?auto=format&fit=crop&w=800&q=80',
  };

  static String forCategory(String categoryId) =>
      byCategory[categoryId] ?? byCategory['salon']!;
}
