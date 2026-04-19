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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 780;
        final sectionGap = isCompactHeight ? 10.0 : 14.0;
        final horizontalCompact = constraints.maxWidth < 380;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: controller.scientificMode ? 4 : 4,
              child: _buildTopSection(
                context,
                isCompactHeight: isCompactHeight,
                horizontalCompact: horizontalCompact,
                sectionGap: sectionGap,
              ),
            ),
            if (controller.scientificMode) ...<Widget>[
              SizedBox(height: sectionGap),
              Expanded(
                flex: 2,
                child: _buildScientificSection(
                  context,
                  isCompactHeight: isCompactHeight,
                ),
              ),
            ],
            SizedBox(height: sectionGap),
            Expanded(
              flex: controller.scientificMode ? 4 : 6,
              child: _buildResponsiveButtonGrid(
                buttons: _basicButtonSpecs(),
                isCompactHeight: isCompactHeight,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopSection(
    BuildContext context, {
    required bool isCompactHeight,
    required bool horizontalCompact,
    required double sectionGap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
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
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: isCompactHeight ? 24 : null,
                            ),
                          ),
                          if (!isCompactHeight) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              'History, scientific tools, and quick theme switching.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                    const SizedBox(width: 8),
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
                SizedBox(height: sectionGap),
                Wrap(
                  spacing: isCompactHeight ? 8 : 12,
                  runSpacing: isCompactHeight ? 8 : 12,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: horizontalCompact ? 200 : 260,
                        maxWidth: 400,
                      ),
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
                      label: Text(
                        controller.useDegrees ? 'Angle: DEG' : 'Angle: RAD',
                      ),
                      onSelected: (_) => controller.toggleAngleUnit(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: sectionGap),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isCompactHeight ? 14 : 22),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.74),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
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
                  SizedBox(height: isCompactHeight ? 6 : 10),
                  LayoutBuilder(
                    builder: (context, displayConstraints) {
                      return SizedBox(
                        width: displayConstraints.maxWidth,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            controller.displayExpression,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isCompactHeight ? 21 : 30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isCompactHeight ? 8 : 12),
                  Text(
                    'Result',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 4 : 8),
                  LayoutBuilder(
                    builder: (context, resultConstraints) {
                      return SizedBox(
                        width: resultConstraints.maxWidth,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            controller.previewResult,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: isCompactHeight ? 27 : 36,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScientificSection(
    BuildContext context, {
    required bool isCompactHeight,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompactHeight ? 10 : 12,
        isCompactHeight ? 8 : 10,
        isCompactHeight ? 10 : 12,
        isCompactHeight ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Scientific Tools',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isCompactHeight ? 8 : 10),
          Expanded(
            child: _buildResponsiveButtonGrid(
              buttons: _scientificButtonSpecs(),
              isCompactHeight: isCompactHeight,
              compactPreferredTileHeight: 46,
              regularPreferredTileHeight: 54,
              minTileHeight: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveButtonGrid({
    required List<_CalculatorButtonSpec> buttons,
    required bool isCompactHeight,
    double compactPreferredTileHeight = 64,
    double regularPreferredTileHeight = 76,
    double minTileHeight = 42,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        final spacing = isCompactHeight ? 8.0 : 12.0;
        final rowCount = (buttons.length / columns).ceil();

        final maxTileHeight = math.max(
          1,
          (constraints.maxHeight - ((rowCount - 1) * spacing)) / rowCount,
        );
        final preferredTileHeight = isCompactHeight
            ? compactPreferredTileHeight
            : regularPreferredTileHeight;
        final canFitWithoutScroll = maxTileHeight >= minTileHeight;
        final tileHeight = canFitWithoutScroll
            ? math.min(preferredTileHeight, maxTileHeight)
            : minTileHeight;

        final tileWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        final aspectRatio = math.max(tileWidth / tileHeight, 0.72);

        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: buttons.length,
          physics: canFitWithoutScroll
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
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
    );
  }

  List<_CalculatorButtonSpec> _scientificButtonSpecs() {
    return <_CalculatorButtonSpec>[
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
    ];
  }

  List<_CalculatorButtonSpec> _basicButtonSpecs() {
    return <_CalculatorButtonSpec>[
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
