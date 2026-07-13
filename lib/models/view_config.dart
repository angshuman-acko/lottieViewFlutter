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

/// Sizing configuration for the Lottie preview.
class ViewConfig {
  const ViewConfig({
    this.mode = ViewMode.full,
    this.width,
    this.height,
    this.aspectWidth = 1,
    this.aspectHeight = 1,
    this.backgroundColorHex = '#1A1D23',
  });

  final ViewMode mode;
  final double? width;
  final double? height;
  final double aspectWidth;
  final double aspectHeight;
  final String backgroundColorHex;

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
    String? backgroundColorHex,
  }) {
    return ViewConfig(
      mode: mode ?? this.mode,
      width: clearWidth ? null : (width ?? this.width),
      height: clearHeight ? null : (height ?? this.height),
      aspectWidth: aspectWidth ?? this.aspectWidth,
      aspectHeight: aspectHeight ?? this.aspectHeight,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
    );
  }
}
