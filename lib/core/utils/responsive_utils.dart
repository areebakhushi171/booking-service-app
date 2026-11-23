import 'dart:ui';

import 'package:flutter/widgets.dart';

/// ScreenUtil design-size selection.
/// Phones design at 390x844. On tablets/desktop (shortest side >= 600) the
/// design size is 768x1024 so `.w/.h/.sp` do not blow up on large screens.
class ResponsiveUtils {
  ResponsiveUtils._();

  static const Size phoneDesignSize = Size(390, 844);
  static const Size tabletDesignSize = Size(768, 1024);

  static Size designSize() {
    final view = PlatformDispatcher.instance.views.first;
    final logical = view.physicalSize / view.devicePixelRatio;
    return logical.shortestSide >= 600 ? tabletDesignSize : phoneDesignSize;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 720;
}
