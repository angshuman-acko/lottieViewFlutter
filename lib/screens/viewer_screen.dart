import 'package:flutter/material.dart';

import '../models/lottie_source.dart';
import '../models/view_config.dart';
import '../theme/app_theme.dart';
import '../widgets/lottie_stage.dart';
import '../widgets/source_panel.dart';
import '../widgets/view_options_panel.dart';

/// Main screen for the internal Lottie preview tool.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  LottieSource? _source;
  ViewConfig _config = const ViewConfig();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF12171F),
              AppColors.canvas,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Controls can scroll on short screens; preview keeps a
                    // stable share of the viewport and never collapses to 0.
                    Flexible(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(theme: theme),
                            const SizedBox(height: 22),
                            SourcePanel(
                              source: _source,
                              onSourceChanged: (source) {
                                setState(() => _source = source);
                              },
                            ),
                            const SizedBox(height: 14),
                            ViewOptionsPanel(
                              config: _config,
                              onChanged: (config) {
                                setState(() => _config = config);
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LottieStage(
                        source: _source,
                        config: _config,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lottie Viewer',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 6),
              Text(
                'Internal Flutter tool to preview Lottie from URL or local file.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            'FLUTTER WEB',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
