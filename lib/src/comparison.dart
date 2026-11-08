import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'controller.dart';
import 'font_preview.dart';
import 'preview_tools.dart';
import 'font_export.dart';
import 'localization.dart';

class ComparisonPage extends StatelessWidget {
  const ComparisonPage({super.key, required this.controller});
  final FontController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.compare)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showSampleEditor(context, c),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.l10n.customSample),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (context, _) => SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: TypographyControls(controller: c),
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.tune),
                    label: Text(context.l10n.previewOptions),
                  ),
                ],
              ),
              if (c.comparisonFonts.length < 2)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.compareNeedTwo),
                ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, bounds) {
                  final columns = bounds.maxWidth >= 1100
                      ? math.max(2, c.comparisonFonts.length)
                      : 2;
                  final width =
                      (bounds.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final face in c.comparisonFonts)
                        SizedBox(
                          width: width,
                          child: Card.outlined(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    face.name,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    face.style,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    key: ValueKey('comparison:${face.id}'),
                                    height: 300,
                                    padding: const EdgeInsets.all(8),
                                    color: c.paper,
                                    child: ClipRect(
                                      child: FontPreview(
                                        service: c.service,
                                        face: face,
                                        text: c.sample,
                                        size: c.size,
                                        color: c.ink,
                                        letterSpacing: c.letterSpacing,
                                        lineHeight: c.lineHeight,
                                        alignment: c.alignment,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    children: [
                                      IconButton(
                                        tooltip: context.l10n.exportImage,
                                        onPressed: () =>
                                            showFontExport(context, c, face),
                                        icon: const Icon(
                                          Icons.ios_share,
                                          size: 20,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: context.l10n.removeFromCompare,
                                        onPressed: () =>
                                            c.toggleComparison(face.id),
                                        icon: const Icon(Icons.close, size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
