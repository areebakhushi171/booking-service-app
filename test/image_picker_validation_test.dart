import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bookease/core/utils/image_picker_helper.dart';

void main() {
  test('image picker validation matches backend format and byte limits',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'bookease-image-validation-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final exactlyFiveMiB = File('${directory.path}/valid.png');
    await exactlyFiveMiB.writeAsBytes(
      List<int>.filled(ImagePickerHelper.maxFileSizeBytes, 0),
    );
    expect(ImagePickerHelper.validateImage(exactlyFiveMiB), isNull);

    final tooLarge = File('${directory.path}/too-large.png');
    await tooLarge.writeAsBytes(
      List<int>.filled(ImagePickerHelper.maxFileSizeBytes + 1, 0),
    );
    expect(ImagePickerHelper.validateImage(tooLarge), contains('5 MB'));

    final unsupported = File('${directory.path}/unsupported.heic');
    await unsupported.writeAsBytes([0]);
    expect(
      ImagePickerHelper.validateImage(unsupported),
      contains('Use JPG, PNG, or WEBP'),
    );
  });
}
