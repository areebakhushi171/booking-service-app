import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Maximum allowed file size in bytes (5 MB per backend contract).
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Maximum allowed gallery images per service.
  static const int maxGalleryImages = 5;

  /// Allowed image file extensions.
  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Pick a single image from [source] (camera or gallery).
  static Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file == null) return null;

      final imageFile = File(file.path);
      final validationError = validateImage(imageFile);
      if (validationError != null) {
        throw Exception(validationError);
      }

      return imageFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick multiple images from gallery with max limit enforcement.
  static Future<List<File>> pickMultiImage({int currentCount = 0}) async {
    try {
      final remainingSlots = maxGalleryImages - currentCount;
      if (remainingSlots <= 0) {
        throw Exception(
            'You can add a maximum of $maxGalleryImages gallery images.');
      }

      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (files.isEmpty) return [];

      final List<File> validFiles = [];
      for (final xf in files) {
        if (validFiles.length >= remainingSlots) break;
        final f = File(xf.path);
        final err = validateImage(f);
        if (err == null) {
          validFiles.add(f);
        } else {
          throw Exception(err);
        }
      }
      return validFiles;
    } catch (e) {
      rethrow;
    }
  }

  /// Validates format and size of [file]. Returns error message if invalid, null if valid.
  static String? validateImage(File file) {
    if (!file.existsSync()) {
      return 'Selected image file does not exist.';
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Unsupported image format ($ext). Use JPG, PNG, or WEBP.';
    }

    final size = file.lengthSync();
    if (size > maxFileSizeBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      return 'Image size ($sizeMb MB) exceeds the 5 MB backend limit.';
    }

    return null;
  }

  /// Shows a modal bottom sheet allowing the user to select source.
  static Future<void> showImageSourcePicker({
    required BuildContext context,
    required Function(File image) onImageSelected,
    String title = 'Select Image',
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.photo_library_rounded),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final file = await pickImage(ImageSource.gallery);
                      if (file != null) onImageSelected(file);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.camera_alt_rounded),
                  ),
                  title: const Text('Take Photo with Camera'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final file = await pickImage(ImageSource.camera);
                      if (file != null) onImageSelected(file);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
