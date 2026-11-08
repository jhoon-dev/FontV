import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'font_service.dart';
import 'localization.dart';

/// The OS renders its own fonts, preserving collection indexes and variation axes.
class FontPreview extends StatefulWidget {
  const FontPreview({
    super.key,
    required this.service,
    required this.face,
    required this.text,
    required this.size,
    required this.color,
    this.thumbnail = false,
    this.letterSpacing = 0,
    this.lineHeight = 1.35,
    this.alignment = PreviewAlignment.left,
  });
  final FontService service;
  final FontFace face;
  final String text;
  final double size;
  final Color color;
  final bool thumbnail;
  final double letterSpacing;
  final double lineHeight;
  final PreviewAlignment alignment;
  @override
  State<FontPreview> createState() => _FontPreviewState();
}

class _FontPreviewState extends State<FontPreview> {
  Timer? _timer;
  String? _key;
  Uint8List? _bytes;
  bool _failed = false;
  int _generation = 0;
  void _request(PreviewRequest request) {
    if (_key == request.cacheKey) return;
    _key = request.cacheKey;
    final generation = ++_generation;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: widget.thumbnail ? 0 : 90), () async {
      try {
        final bytes = await widget.service.render(request);
        if (mounted && generation == _generation) {
          setState(() {
            _bytes = bytes;
            _failed = false;
          });
        }
      } catch (_) {
        if (mounted && generation == _generation) {
          setState(() => _failed = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.service.isDemo) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          widget.text,
          maxLines: widget.thumbnail ? 1 : null,
          textAlign: switch (widget.alignment) {
            PreviewAlignment.left => TextAlign.left,
            PreviewAlignment.center => TextAlign.center,
            PreviewAlignment.right => TextAlign.right,
          },
          style: TextStyle(
            fontWeight: widget.face.id == 'demo:bold'
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: widget.face.id == 'demo:italic'
                ? FontStyle.italic
                : FontStyle.normal,
            fontSize: widget.size,
            height: widget.lineHeight,
            letterSpacing: widget.letterSpacing,
            color: widget.color,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.maxWidth <= 0 || bounds.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        _request(
          PreviewRequest(
            fontId: widget.face.id,
            text: widget.text,
            size: widget.size,
            color: widget.color.toARGB32(),
            width: bounds.maxWidth,
            height: bounds.maxHeight,
            scale: MediaQuery.devicePixelRatioOf(context).clamp(1, 3),
            letterSpacing: widget.letterSpacing,
            lineHeight: widget.lineHeight,
            alignment: widget.alignment,
          ),
        );
        if (_failed) {
          return Center(
            child: IconButton(
              tooltip: context.l10n.previewRetry,
              onPressed: () => setState(() {
                _key = null;
                _failed = false;
              }),
              icon: const Icon(Icons.refresh_rounded),
            ),
          );
        }
        if (_bytes == null) {
          return Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: widget.color.withValues(alpha: .35),
              ),
            ),
          );
        }
        return Image.memory(
          _bytes!,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        );
      },
    );
  }

  @override
  void didUpdateWidget(FontPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face.id != widget.face.id) _bytes = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
