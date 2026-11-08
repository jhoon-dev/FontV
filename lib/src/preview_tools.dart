import 'package:flutter/material.dart';
import 'controller.dart';
import 'font_service.dart';
import 'localization.dart';
import 'color_picker.dart';

class TypographyControls extends StatelessWidget {
  const TypographyControls({
    super.key,
    required this.controller,
    this.includeSize = true,
  });
  final FontController controller;
  final bool includeSize;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    Widget control(String label, String value, Widget slider) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: TextStyle(color: c.skin.color)),
          ],
        ),
        slider,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeSize)
          control(
            context.l10n.fontSize,
            '${c.size.round()} pt',
            Slider(
              key: const Key('comparison-size'),
              value: c.size,
              min: 12,
              max: 96,
              divisions: 84,
              label: '${c.size.round()} pt',
              onChanged: c.setSize,
            ),
          ),
        control(
          context.l10n.letterSpacing,
          '${c.letterSpacing.toStringAsFixed(1)} pt',
          Slider(
            key: const Key('letter-spacing'),
            value: c.letterSpacing,
            min: -2,
            max: 12,
            divisions: 28,
            label: c.letterSpacing.toStringAsFixed(1),
            onChanged: c.setLetterSpacing,
          ),
        ),
        control(
          context.l10n.lineHeight,
          '${c.lineHeight.toStringAsFixed(2)}×',
          Slider(
            key: const Key('line-height'),
            value: c.lineHeight,
            min: 1,
            max: 2.5,
            divisions: 30,
            label: c.lineHeight.toStringAsFixed(2),
            onChanged: c.setLineHeight,
          ),
        ),
        Text(context.l10n.alignment),
        const SizedBox(height: 8),
        SegmentedButton<PreviewAlignment>(
          key: const Key('text-alignment'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: PreviewAlignment.left,
              icon: const Icon(Icons.format_align_left),
              tooltip: context.l10n.alignLeft,
            ),
            ButtonSegment(
              value: PreviewAlignment.center,
              icon: const Icon(Icons.format_align_center),
              tooltip: context.l10n.alignCenter,
            ),
            ButtonSegment(
              value: PreviewAlignment.right,
              icon: const Icon(Icons.format_align_right),
              tooltip: context.l10n.alignRight,
            ),
          ],
          selected: {c.alignment},
          onSelectionChanged: (values) => c.setAlignment(values.single),
        ),
        if (includeSize) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => pickPreviewColor(context, c, true),
                icon: Icon(Icons.format_color_text, color: c.ink),
                label: Text(context.l10n.textColor),
              ),
              OutlinedButton.icon(
                onPressed: () => pickPreviewColor(context, c, false),
                icon: const Icon(Icons.format_color_fill),
                label: Text(context.l10n.backgroundColor),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class CharacterSupportCard extends StatefulWidget {
  const CharacterSupportCard({
    super.key,
    required this.service,
    required this.face,
    required this.text,
  });
  final FontService service;
  final FontFace face;
  final String text;
  @override
  State<CharacterSupportCard> createState() => _CharacterSupportCardState();
}

class _CharacterSupportCardState extends State<CharacterSupportCard> {
  late Future<GlyphCoverage> _future;
  void _load() =>
      _future = widget.service.checkGlyphs(widget.face.id, widget.text);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CharacterSupportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face.id != widget.face.id ||
        oldWidget.text != widget.text ||
        oldWidget.service != widget.service) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.coverageTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          FutureBuilder<GlyphCoverage>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return TextButton.icon(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.coverageError),
                );
              }
              final coverage = snapshot.data!;
              if (!coverage.available) return Text(context.l10n.deviceFeature);
              if (coverage.complete) {
                return Text(
                  context.l10n.coverageComplete,
                  key: const Key('coverage-complete'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.coverageMissing),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final rune in coverage.missing)
                        Chip(
                          label: Text(
                            '${String.fromCharCode(rune)} · U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.coverageHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

Future<void> showSampleEditor(
  BuildContext context,
  FontController controller,
) async {
  final text = TextEditingController(text: controller.sample);
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.sampleDialogTitle),
      content: SizedBox(
        width: 440,
        child: TextField(
          key: const Key('sample-input'),
          controller: text,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          maxLength: 1000,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, text.text),
          child: Text(context.l10n.apply),
        ),
      ],
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  text.dispose();
  if (value != null) controller.setSample(value);
}
