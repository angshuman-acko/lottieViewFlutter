import 'dart:typed_data';

/// Source of a Lottie animation — either a remote URL or local file bytes.
sealed class LottieSource {
  const LottieSource();

  String get label;
}

final class UrlLottieSource extends LottieSource {
  const UrlLottieSource(this.url);

  final String url;

  @override
  String get label => url;
}

final class FileLottieSource extends LottieSource {
  const FileLottieSource({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;

  @override
  String get label => name;
}
