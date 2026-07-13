import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lottie_source.dart';
import '../theme/app_theme.dart';

/// URL paste + local file picker for loading a Lottie animation.
class SourcePanel extends StatefulWidget {
  const SourcePanel({
    super.key,
    required this.source,
    required this.onSourceChanged,
  });

  final LottieSource? source;
  final ValueChanged<LottieSource?> onSourceChanged;

  @override
  State<SourcePanel> createState() => _SourcePanelState();
}

class _SourcePanelState extends State<SourcePanel> {
  late final TextEditingController _urlController;
  String? _error;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.source;
    _urlController = TextEditingController(
      text: initial is UrlLottieSource ? initial.url : '',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _loadUrl() {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Paste a Lottie JSON URL first.');
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      setState(() => _error = 'Enter a valid http(s) URL.');
      return;
    }

    setState(() => _error = null);
    widget.onSourceChanged(UrlLottieSource(raw));
  }

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _error = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'lottie'],
        withData: true,
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() => _picking = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _picking = false;
          _error = 'Could not read file bytes. Try another file.';
        });
        return;
      }

      _urlController.clear();
      setState(() => _picking = false);
      widget.onSourceChanged(
        FileLottieSource(name: file.name, bytes: bytes),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = 'File picker failed: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = 'Could not open file: $e';
      });
    }
  }

  void _clear() {
    _urlController.clear();
    setState(() => _error = null);
    widget.onSourceChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = widget.source;

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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Source',
                style: theme.textTheme.headlineMedium,
              ),
              const Spacer(),
              if (source != null)
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Paste a remote Lottie URL or pick a .json / .lottie file from your computer. Files stay local — nothing is uploaded.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final urlField = TextField(
                controller: _urlController,
                onSubmitted: (_) => _loadUrl(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Lottie URL',
                  hintText: 'https://example.com/animation.json',
                  prefixIcon: Icon(Icons.link_rounded, size: 20),
                ),
              );

              final actions = Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loadUrl,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Load URL'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking ? null : _pickFile,
                      icon: _picking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(_picking ? 'Opening…' : 'Pick file'),
                    ),
                  ),
                ],
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: urlField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: actions),
                  ],
                );
              }

              return Column(
                children: [
                  urlField,
                  const SizedBox(height: 12),
                  actions,
                ],
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              text: _error!,
            ),
          ],
          if (source != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              icon: source is FileLottieSource
                  ? Icons.insert_drive_file_outlined
                  : Icons.cloud_done_outlined,
              color: AppColors.accent,
              text: source is FileLottieSource
                  ? 'Local file · ${source.name} · ${(source.bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB'
                  : 'Remote URL · ${source.label}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
