import 'package:flutter/material.dart';

/// How the Lottie animation is sized inside the preview stage.
enum ViewMode {
  /// Fill the entire available preview area.
  full,

  /// Explicit pixel width and/or height.
  custom,

  /// Constrain by width:height aspect ratio.
  aspectRatio,
}

extension ViewModeLabel on ViewMode {
  String get label => switch (this) {
        ViewMode.full => 'Full',
        ViewMode.custom => 'Custom',
        ViewMode.aspectRatio => 'Aspect ratio',
      };

  String get description => switch (this) {
        ViewMode.full => 'Fill available width and height',
        ViewMode.custom => 'Set explicit width and/or height',
        ViewMode.aspectRatio => 'Lock to a width:height ratio',
      };
}

/// Preview stage background behind the Lottie.
enum BackgroundMode {
  /// Checkerboard — shows transparency.
  transparent,

  /// Solid white.
  white,

  /// User-picked solid color.
  custom,
}

extension BackgroundModeLabel on BackgroundMode {
  String get label => switch (this) {
        BackgroundMode.transparent => 'Transparent',
        BackgroundMode.white => 'White',
        BackgroundMode.custom => 'Custom',
      };
}

/// Sizing + background configuration for the Lottie preview.
class ViewConfig {
  const ViewConfig({
    this.mode = ViewMode.full,
    this.width,
    this.height,
    this.aspectWidth = 1,
    this.aspectHeight = 1,
    this.backgroundMode = BackgroundMode.transparent,
    this.customBackground = const Color(0xFF1A1D23),
  });

  final ViewMode mode;
  final double? width;
  final double? height;
  final double aspectWidth;
  final double aspectHeight;
  final BackgroundMode backgroundMode;
  final Color customBackground;

  double get aspectRatio {
    if (aspectHeight == 0) return 1;
    return aspectWidth / aspectHeight;
  }

  ViewConfig copyWith({
    ViewMode? mode,
    double? width,
    bool clearWidth = false,
    double? height,
    bool clearHeight = false,
    double? aspectWidth,
    double? aspectHeight,
    BackgroundMode? backgroundMode,
    Color? customBackground,
  }) {
    return ViewConfig(
      mode: mode ?? this.mode,
      width: clearWidth ? null : (width ?? this.width),
      height: clearHeight ? null : (height ?? this.height),
      aspectWidth: aspectWidth ?? this.aspectWidth,
      aspectHeight: aspectHeight ?? this.aspectHeight,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      customBackground: customBackground ?? this.customBackground,
    );
  }
}

/// Parses `#RGB`, `#RRGGBB`, or `#AARRGGBB` into a [Color].
Color? parseHexColor(String raw) {
  var hex = raw.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

String colorToHex(Color color, {bool includeHash = true}) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  final rgb = argb.substring(2);
  return includeHash ? '#$rgb' : rgb;
}
