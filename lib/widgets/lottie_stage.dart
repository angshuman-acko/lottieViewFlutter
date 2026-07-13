import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/lottie_source.dart';
import '../models/view_config.dart';
import '../theme/app_theme.dart';

/// Renders the loaded Lottie with sizing + playback controls.
class LottieStage extends StatefulWidget {
  const LottieStage({
    super.key,
    required this.source,
    required this.config,
  });

  final LottieSource? source;
  final ViewConfig config;

  @override
  State<LottieStage> createState() => _LottieStageState();
}

class _LottieStageState extends State<LottieStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _speed = 1;
  bool _loop = true;
  String? _loadError;
  LottieComposition? _composition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(covariant LottieStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _resetPlayback();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (!_loop && status == AnimationStatus.completed) {
      // Stay on last frame when looping is off.
    }
  }

  void _resetPlayback() {
    _loadError = null;
    _composition = null;
    _controller
      ..stop()
      ..reset()
      ..duration = null;
  }

  void _onLoaded(LottieComposition composition) {
    if (!mounted) return;
    setState(() {
      _composition = composition;
      _loadError = null;
      _controller.duration = Duration(
        microseconds: (composition.duration.inMicroseconds / _speed).round(),
      );
    });
    if (_loop) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else if (_controller.value >= 1 && !_loop) {
      _controller.forward(from: 0);
    } else {
      if (_loop) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
    setState(() {});
  }

  void _setLoop(bool value) {
    setState(() => _loop = value);
    if (value && !_controller.isAnimating && _composition != null) {
      _controller.repeat();
    }
  }

  void _setSpeed(double value) {
    setState(() => _speed = value);
    _controller.duration = _composition == null
        ? null
        : Duration(
            microseconds:
                (_composition!.duration.inMicroseconds / value).round(),
          );
    if (_controller.isAnimating) {
      if (_loop) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  Widget _buildLottie() {
    final source = widget.source;
    if (source == null) {
      return const _EmptyStage();
    }

    final lottie = switch (source) {
      UrlLottieSource(:final url) => Lottie.network(
          url,
          key: ValueKey('url:$url'),
          controller: _controller,
          onLoaded: _onLoaded,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _loadError = error.toString());
              }
            });
            return _ErrorStage(message: error.toString());
          },
        ),
      FileLottieSource(:final bytes, :final name) => Lottie.memory(
          bytes,
          key: ValueKey('file:$name:${bytes.lengthInBytes}'),
          controller: _controller,
          onLoaded: _onLoaded,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _loadError = error.toString());
              }
            });
            return _ErrorStage(message: error.toString());
          },
        ),
    };

    return _SizedLottie(config: widget.config, child: lottie);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSource = widget.source != null;
    final frames = _composition?.durationFrames;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Text('Preview', style: theme.textTheme.headlineMedium),
                const Spacer(),
                if (_composition != null)
                  Text(
                    '${_composition!.bounds.width.toInt()}×'
                    '${_composition!.bounds.height.toInt()}'
                    '${frames != null ? ' · ${frames.toStringAsFixed(0)}f' : ''}'
                    ' · ${_composition!.duration.inMilliseconds}ms',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF12161E),
                    Color(0xFF0B0E13),
                  ],
                ),
              ),
              child: ClipRect(
                child: CustomPaint(
                  painter: const _CheckerPainter(),
                  child: SizedBox.expand(
                    child: Center(child: _buildLottie()),
                  ),
                ),
              ),
            ),
          ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                _loadError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.danger,
                  fontSize: 12,
                ),
              ),
            ),
          _PlaybackBar(
            enabled: hasSource && _composition != null,
            isPlaying: _controller.isAnimating,
            loop: _loop,
            speed: _speed,
            progress: _controller,
            onTogglePlay: _togglePlay,
            onLoopChanged: _setLoop,
            onSpeedChanged: _setSpeed,
            onSeek: (value) {
              _controller.value = value;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _SizedLottie extends StatelessWidget {
  const _SizedLottie({
    required this.config,
    required this.child,
  });

  final ViewConfig config;
  final Widget child;

  Size _aspectSize(BoxConstraints constraints) {
    final ratio = config.aspectRatio;
    var width = constraints.maxWidth;
    var height = width / ratio;
    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * ratio;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (config.mode) {
          case ViewMode.full:
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: child,
            );
          case ViewMode.custom:
            return SizedBox(
              width: config.width,
              height: config.height,
              child: child,
            );
          case ViewMode.aspectRatio:
            final size = _aspectSize(constraints);
            return SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            );
        }
      },
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({
    required this.enabled,
    required this.isPlaying,
    required this.loop,
    required this.speed,
    required this.progress,
    required this.onTogglePlay,
    required this.onLoopChanged,
    required this.onSpeedChanged,
    required this.onSeek,
  });

  final bool enabled;
  final bool isPlaying;
  final bool loop;
  final double speed;
  final Animation<double> progress;
  final VoidCallback onTogglePlay;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              return Slider(
                value: progress.value.clamp(0.0, 1.0),
                onChanged: enabled ? onSeek : null,
              );
            },
          ),
          Row(
            children: [
              IconButton(
                onPressed: enabled ? onTogglePlay : null,
                tooltip: isPlaying ? 'Pause' : 'Play',
                icon: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                color: AppColors.accent,
              ),
              IconButton(
                onPressed: enabled ? () => onLoopChanged(!loop) : null,
                tooltip: loop ? 'Looping on' : 'Looping off',
                icon: Icon(
                  loop ? Icons.repeat_rounded : Icons.repeat_one_rounded,
                ),
                color: loop ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Speed',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: Slider(
                  min: 0.25,
                  max: 2,
                  divisions: 7,
                  value: speed,
                  onChanged: enabled ? onSpeedChanged : null,
                ),
              ),
              Text(
                '${speed.toStringAsFixed(2)}×',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStage extends StatelessWidget {
  const _EmptyStage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.animation_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              'No animation loaded',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Load a URL or pick a local Lottie file to preview it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStage extends StatelessWidget {
  const _ErrorStage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load Lottie',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 16.0;
    final paintA = Paint()..color = AppColors.checkerA;
    final paintB = Paint()..color = AppColors.checkerB;

    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final odd = ((x / cell).floor() + (y / cell).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          odd ? paintB : paintA,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
