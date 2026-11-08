import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller.dart';
import 'localization.dart';

class ImportedFontsPage extends StatefulWidget {
  const ImportedFontsPage({super.key, required this.controller, this.pickFile});
  final FontController controller;
  final Future<XFile?> Function()? pickFile;
  @override
  State<ImportedFontsPage> createState() => _ImportedFontsPageState();
}

class _ImportedFontsPageState extends State<ImportedFontsPage> {
  bool _busy = false;
  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final file =
          await (widget.pickFile?.call() ??
              openFile(
                acceptedTypeGroups: const [
                  XTypeGroup(
                    label: 'TTF / OTF',
                    extensions: ['ttf', 'otf'],
                    mimeTypes: [
                      'font/ttf',
                      'font/otf',
                      'application/x-font-ttf',
                      'application/x-font-opentype',
                      'application/vnd.ms-opentype',
                      'application/octet-stream',
                    ],
                    uniformTypeIdentifiers: ['public.font'],
                  ),
                ],
              ));
      if (file == null) return;
      if (await file.length() > 32 * 1024 * 1024) {
        throw PlatformException(code: 'FONT_TOO_LARGE');
      }
      await widget.controller.importFont(await file.readAsBytes(), file.name);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.importSuccess)));
      }
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        PlatformException(code: 'FONT_TOO_LARGE') =>
          context.l10n.importTooLarge,
        PlatformException(code: 'FONT_LIMIT') => context.l10n.importLimit,
        PlatformException(code: 'FONT_INVALID') => context.l10n.importInvalid,
        _ => context.l10n.importFailed,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final fonts = c.fonts.where((f) => f.imported).toList();
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.importedFonts)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(context.l10n.importHelp),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('pick-font-file'),
                onPressed: _busy || c.service.isDemo ? null : _import,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(context.l10n.importFonts),
              ),
              if (c.service.isDemo) Text(context.l10n.deviceFeature),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 20),
              if (fonts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(context.l10n.importEmpty),
                ),
              for (final face in fonts)
                Card.outlined(
                  child: ListTile(
                    key: ValueKey('imported:${face.id}'),
                    title: Text(face.name),
                    subtitle: Text('${face.family} · ${face.style}'),
                    onTap: _busy ? null : () => Navigator.pop(context, face),
                    trailing: IconButton(
                      tooltip: context.l10n.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(context.l10n.removeImportedTitle),
                                  content: Text(
                                    context.l10n.removeImportedBody,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(context.l10n.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(context.l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !mounted) return;
                              setState(() => _busy = true);
                              try {
                                await c.removeImportedFont(face.id);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.l10n.importFailed),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
