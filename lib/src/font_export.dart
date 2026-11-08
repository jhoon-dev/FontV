import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'controller.dart';
import 'font_service.dart';
import 'localization.dart';

class FontImageExporter {
  const FontImageExporter(this.service);
  final FontService service;

  Future<Uint8List> render({
    required FontFace face,
    required PreviewRequest request,
    required Color paper,
    bool includeInfo = true,
    bool transparent = false,
  }) async {
    final bytes = await service.render(request);
    final codec = await ui.instantiateImageCodec(bytes);
    ui.Image? preview;
    ui.Image? output;
    ui.Picture? picture;
    try {
      preview = (await codec.getNextFrame()).image;
      const padding = 48.0;
      final footer = includeInfo ? 156.0 : 0.0;
      final width = preview.width + padding * 2;
      final height = preview.height + padding * 2 + footer;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      if (!transparent) canvas.drawColor(paper, BlendMode.src);
      canvas.drawImage(preview, const Offset(padding, padding), Paint());
      if (includeInfo) {
        String hex(int value) =>
            '#${(value & 0xffffff).toRadixString(16).toUpperCase().padLeft(6, '0')}';
        final painter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 4,
          ellipsis: '…',
          text: TextSpan(
            text:
                '${face.name}\n${request.size.round()} pt · ${request.letterSpacing.toStringAsFixed(1)} pt · ${request.lineHeight.toStringAsFixed(2)}× · ${request.alignment.name}\n${hex(request.color)} / ${transparent ? 'PNG α' : hex(paper.toARGB32())}',
            style: TextStyle(
              fontSize: 26,
              height: 1.35,
              color: Color(request.color),
            ),
          ),
        )..layout(maxWidth: width - padding * 2);
        painter.paint(canvas, Offset(padding, preview.height + padding * 1.5));
        painter.dispose();
      }
      picture = recorder.endRecording();
      output = await picture.toImage(width.round(), height.round());
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      output?.dispose();
      picture?.dispose();
      preview?.dispose();
      codec.dispose();
    }
  }
}

Future<void> showFontExport(
  BuildContext context,
  FontController controller,
  FontFace face,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _ExportSheet(controller: controller, face: face),
);

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.controller, required this.face});
  final FontController controller;
  final FontFace face;
  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _info = true;
  bool _transparent = false;
  bool _busy = false;
  Future<Uint8List>? _preview;

  @override
  void initState() {
    super.initState();
    _refreshPreview();
  }

  void _refreshPreview() {
    if (widget.controller.service.isDemo) return;
    final c = widget.controller;
    _preview = FontImageExporter(c.service).render(
      face: widget.face,
      paper: c.paper,
      includeInfo: _info,
      transparent: _transparent,
      request: PreviewRequest(
        fontId: widget.face.id,
        text: c.sample,
        size: c.size,
        color: c.ink.toARGB32(),
        width: 540,
        height: 360,
        scale: 2,
        letterSpacing: c.letterSpacing,
        lineHeight: c.lineHeight,
        alignment: c.alignment,
      ),
    );
  }

  Future<void> _export(bool share) async {
    // Capture the button's valid popover origin before any asynchronous work.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(1, 1, 1, 1);
    setState(() => _busy = true);
    final c = widget.controller;
    try {
      final png = await _preview!;
      if (!mounted) return;
      final safeName = widget.face.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final filename =
          'FontV-${safeName.substring(0, safeName.length.clamp(0, 70))}.png';
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(png, mimeType: 'image/png')],
            fileNameOverrides: [filename],
            sharePositionOrigin: origin,
          ),
        );
      } else {
        final saved = await c.service.saveImage(png, filename);
        if (saved && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.imageSaved)));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.exportFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.exportImage,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.exportHelp),
          if (_preview != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 190,
                child: ColoredBox(
                  color: widget.controller.paper,
                  child: FutureBuilder<Uint8List>(
                    future: _preview,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: TextButton(
                            onPressed: () => setState(_refreshPreview),
                            child: Text(context.l10n.retry),
                          ),
                        );
                      }
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.memory(
                          snapshot.data!,
                          key: const Key('export-image-preview'),
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.exportInfo),
            value: _info,
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _info = v;
                    _refreshPreview();
                  }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.exportTransparent),
            value: _transparent,
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _transparent = v;
                    _refreshPreview();
                  }),
          ),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('export-share'),
            onPressed: _busy || widget.controller.service.isDemo
                ? null
                : () => _export(true),
            icon: const Icon(Icons.ios_share),
            label: Text(context.l10n.shareImage),
          ),
          OutlinedButton.icon(
            key: const Key('export-save'),
            onPressed: _busy || widget.controller.service.isDemo
                ? null
                : () => _export(false),
            icon: const Icon(Icons.save_alt),
            label: Text(context.l10n.saveImage),
          ),
          if (widget.controller.service.isDemo)
            Text(context.l10n.deviceFeature),
        ],
      ),
    ),
  );
}
