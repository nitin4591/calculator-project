import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:modern_calculator/models/history_entry.dart';
import 'package:modern_calculator/services/calculator_controller.dart';
import 'package:modern_calculator/theme/app_theme.dart';
import 'package:modern_calculator/widgets/calculator_button.dart';
import 'package:modern_calculator/widgets/history_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = CalculatorController();
  await controller.initialize();

  runApp(CalculatorRoot(controller: controller));
}

class CalculatorRoot extends StatelessWidget {
  const CalculatorRoot({super.key, required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Modern Calculator',
          debugShowCheckedModeBanner: false,
          themeMode: controller.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: CalculatorHomePage(controller: controller),
        );
      },
    );
  }
}

class CalculatorHomePage extends StatelessWidget {
  const CalculatorHomePage({super.key, required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: _backgroundGradient()),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 960;

                    return Row(
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: _buildCalculatorSurface(context),
                        ),
                        if (isWide) ...<Widget>[
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 320,
                            child: HistorySheet(
                              entries: controller.history,
                              embedded: true,
                              onSelected: controller.useHistoryEntry,
                              onClear: () {
                                controller.clearHistory();
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalculatorSurface(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Modern Calculator',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'History, scientific tools, and quick theme switching.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'History',
              onPressed: () {
                _openHistorySheet(context);
              },
              icon: const Icon(Icons.history_rounded),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: controller.isDarkMode ? 'Light mode' : 'Dark mode',
              onPressed: controller.toggleTheme,
              icon: Icon(
                controller.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.calculate_rounded),
                    label: Text('Basic'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.functions_rounded),
                    label: Text('Scientific'),
                  ),
                ],
                selected: <bool>{controller.scientificMode},
                onSelectionChanged: (selection) {
                  controller.setScientificMode(selection.first);
                },
              ),
            ),
            FilterChip(
              selected: controller.useDegrees,
              avatar: const Icon(Icons.track_changes_rounded, size: 18),
              label:
                  Text(controller.useDegrees ? 'Angle: DEG' : 'Angle: RAD'),
              onSelected: (_) => controller.toggleAngleUnit(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.74),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Expression',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    controller.displayExpression,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Result',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    controller.previewResult,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 42,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          flex: controller.scientificMode ? 6 : 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttons = _buttonSpecs();
              const columns = 4;
              const spacing = 12.0;
              final tileWidth =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
              final desiredHeight = controller.scientificMode ? 72.0 : 84.0;
              final aspectRatio = math.max(tileWidth / desiredHeight, 0.86);

              return GridView.builder(
                itemCount: buttons.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final button = buttons[index];
                  return CalculatorButton(
                    label: button.label,
                    tone: button.tone,
                    onPressed: button.onPressed,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<_CalculatorButtonSpec> _buttonSpecs() {
    return <_CalculatorButtonSpec>[
      if (controller.scientificMode) ...<_CalculatorButtonSpec>[
        _CalculatorButtonSpec(
          label: 'sin',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendFunction('sin'),
        ),
        _CalculatorButtonSpec(
          label: 'cos',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendFunction('cos'),
        ),
        _CalculatorButtonSpec(
          label: 'tan',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendFunction('tan'),
        ),
        _CalculatorButtonSpec(
          label: '^',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendOperator('^'),
        ),
        _CalculatorButtonSpec(
          label: 'ln',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendFunction('ln'),
        ),
        _CalculatorButtonSpec(
          label: 'log',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendFunction('log'),
        ),
        _CalculatorButtonSpec(
          label: 'sqrt',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendFunction('sqrt'),
        ),
        _CalculatorButtonSpec(
          label: '%',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendOperator('%'),
        ),
        _CalculatorButtonSpec(
          label: 'pi',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendConstant('pi'),
        ),
        _CalculatorButtonSpec(
          label: 'e',
          tone: CalculatorButtonTone.accent,
          onPressed: () => controller.appendConstant('e'),
        ),
        _CalculatorButtonSpec(
          label: '!',
          tone: CalculatorButtonTone.accent,
          onPressed: controller.appendFactorial,
        ),
        _CalculatorButtonSpec(
          label: 'x^2',
          tone: CalculatorButtonTone.accent,
          onPressed: controller.appendSquare,
        ),
      ],
      _CalculatorButtonSpec(
        label: 'AC',
        tone: CalculatorButtonTone.danger,
        onPressed: controller.clear,
      ),
      _CalculatorButtonSpec(
        label: 'DEL',
        tone: CalculatorButtonTone.danger,
        onPressed: controller.deleteLast,
      ),
      _CalculatorButtonSpec(
        label: '(',
        tone: CalculatorButtonTone.neutral,
        onPressed: controller.appendOpenParenthesis,
      ),
      _CalculatorButtonSpec(
        label: ')',
        tone: CalculatorButtonTone.neutral,
        onPressed: controller.appendCloseParenthesis,
      ),
      _CalculatorButtonSpec(
        label: '7',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('7'),
      ),
      _CalculatorButtonSpec(
        label: '8',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('8'),
      ),
      _CalculatorButtonSpec(
        label: '9',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('9'),
      ),
      _CalculatorButtonSpec(
        label: '/',
        tone: CalculatorButtonTone.accent,
        onPressed: () => controller.appendOperator('/'),
      ),
      _CalculatorButtonSpec(
        label: '4',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('4'),
      ),
      _CalculatorButtonSpec(
        label: '5',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('5'),
      ),
      _CalculatorButtonSpec(
        label: '6',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('6'),
      ),
      _CalculatorButtonSpec(
        label: '*',
        tone: CalculatorButtonTone.accent,
        onPressed: () => controller.appendOperator('*'),
      ),
      _CalculatorButtonSpec(
        label: '1',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('1'),
      ),
      _CalculatorButtonSpec(
        label: '2',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('2'),
      ),
      _CalculatorButtonSpec(
        label: '3',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('3'),
      ),
      _CalculatorButtonSpec(
        label: '-',
        tone: CalculatorButtonTone.accent,
        onPressed: () => controller.appendOperator('-'),
      ),
      _CalculatorButtonSpec(
        label: '0',
        tone: CalculatorButtonTone.neutral,
        onPressed: () => controller.appendNumber('0'),
      ),
      _CalculatorButtonSpec(
        label: '.',
        tone: CalculatorButtonTone.neutral,
        onPressed: controller.appendDecimal,
      ),
      _CalculatorButtonSpec(
        label: '=',
        tone: CalculatorButtonTone.success,
        onPressed: () {
          controller.evaluate();
        },
      ),
      _CalculatorButtonSpec(
        label: '+',
        tone: CalculatorButtonTone.accent,
        onPressed: () => controller.appendOperator('+'),
      ),
    ];
  }

  Gradient _backgroundGradient() {
    if (controller.isDarkMode) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF020617),
          Color(0xFF0F172A),
          Color(0xFF1E293B),
        ],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0xFFF8FAFC),
        Color(0xFFE0F2FE),
        Color(0xFFDBEAFE),
      ],
    );
  }

  Future<void> _openHistorySheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: HistorySheet(
              entries: controller.history,
              onSelected: (HistoryEntry entry) {
                controller.useHistoryEntry(entry);
                Navigator.of(sheetContext).pop();
              },
              onClear: () {
                controller.clearHistory();
              },
            ),
          ),
        );
      },
    );
  }
}

class _CalculatorButtonSpec {
  const _CalculatorButtonSpec({
    required this.label,
    required this.onPressed,
    required this.tone,
  });

  final String label;
  final VoidCallback onPressed;
  final CalculatorButtonTone tone;
}
