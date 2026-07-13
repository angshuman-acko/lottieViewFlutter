import 'package:flutter/material.dart';

import '../models/view_config.dart';
import '../theme/app_theme.dart';
import 'numeric_field.dart';

/// Controls for preview sizing: full, custom dimensions, or aspect ratio.
class ViewOptionsPanel extends StatefulWidget {
  const ViewOptionsPanel({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final ViewConfig config;
  final ValueChanged<ViewConfig> onChanged;

  @override
  State<ViewOptionsPanel> createState() => _ViewOptionsPanelState();
}

class _ViewOptionsPanelState extends State<ViewOptionsPanel> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _aspectWController;
  late final TextEditingController _aspectHController;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.config.width?.toStringAsFixed(0) ?? '',
    );
    _heightController = TextEditingController(
      text: widget.config.height?.toStringAsFixed(0) ?? '',
    );
    _aspectWController = TextEditingController(
      text: _formatNumber(widget.config.aspectWidth),
    );
    _aspectHController = TextEditingController(
      text: _formatNumber(widget.config.aspectHeight),
    );
  }

  @override
  void didUpdateWidget(covariant ViewOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.width != widget.config.width &&
        _parse(_widthController.text) != widget.config.width) {
      _widthController.text = widget.config.width?.toStringAsFixed(0) ?? '';
    }
    if (oldWidget.config.height != widget.config.height &&
        _parse(_heightController.text) != widget.config.height) {
      _heightController.text = widget.config.height?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _aspectWController.dispose();
    _aspectHController.dispose();
    super.dispose();
  }

  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  static double? _parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  void _setMode(ViewMode mode) {
    widget.onChanged(widget.config.copyWith(mode: mode));
  }

  void _syncCustom() {
    final width = _parse(_widthController.text);
    final height = _parse(_heightController.text);
    widget.onChanged(
      widget.config.copyWith(
        width: width,
        clearWidth: width == null,
        height: height,
        clearHeight: height == null,
      ),
    );
  }

  void _syncAspect() {
    final w = _parse(_aspectWController.text) ?? 1;
    final h = _parse(_aspectHController.text) ?? 1;
    widget.onChanged(
      widget.config.copyWith(
        aspectWidth: w <= 0 ? 1 : w,
        aspectHeight: h <= 0 ? 1 : h,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = widget.config.mode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('View options', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Choose how the animation is framed in the stage below.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<ViewMode>(
            segments: [
              for (final value in ViewMode.values)
                ButtonSegment(
                  value: value,
                  label: Text(value.label),
                  tooltip: value.description,
                ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => _setMode(selection.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (mode) {
              ViewMode.full => _Hint(
                  key: const ValueKey('full'),
                  text:
                      'Animation expands to the full preview stage (available width × height).',
                ),
              ViewMode.custom => KeyedSubtree(
                  key: const ValueKey('custom'),
                  child: Row(
                    children: [
                      Expanded(
                        child: NumericField(
                          label: 'Width',
                          controller: _widthController,
                          hint: 'auto',
                          suffix: 'px',
                          onChanged: (_) => _syncCustom(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NumericField(
                          label: 'Height',
                          controller: _heightController,
                          hint: 'auto',
                          suffix: 'px',
                          onChanged: (_) => _syncCustom(),
                        ),
                      ),
                    ],
                  ),
                ),
              ViewMode.aspectRatio => KeyedSubtree(
                  key: const ValueKey('aspect'),
                  child: Row(
                    children: [
                      Expanded(
                        child: NumericField(
                          label: 'Aspect width',
                          controller: _aspectWController,
                          hint: '16',
                          onChanged: (_) => _syncAspect(),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 22, left: 8, right: 8),
                        child: Text(
                          ':',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: NumericField(
                          label: 'Aspect height',
                          controller: _aspectHController,
                          hint: '9',
                          onChanged: (_) => _syncAspect(),
                        ),
                      ),
                    ],
                  ),
                ),
            },
          ),
          if (mode == ViewMode.custom) ...[
            const SizedBox(height: 10),
            Text(
              'Leave a dimension empty to let that axis size itself.',
              style: theme.textTheme.labelSmall,
            ),
          ],
          if (mode == ViewMode.aspectRatio) ...[
            const SizedBox(height: 10),
            Text(
              'Current ratio ${widget.config.aspectWidth}:${widget.config.aspectHeight} '
              '(${widget.config.aspectRatio.toStringAsFixed(3)})',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
