import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller.dart';
import 'font_preview.dart';
import 'font_catalog.dart';
import 'localization.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'font_service.dart';
import 'ads.dart';
import 'collection_tools.dart';
import 'comparison.dart';
import 'import_tools.dart';
import 'preview_tools.dart';
import 'font_export.dart';
import 'color_picker.dart';

const _canvas = Color(0xFFF8F7F4);
const _text = Color(0xFF242329);
const _muted = Color(0xFF78767E);
const _line = Color(0xFFE8E5E2);

class FontVApp extends StatefulWidget {
  const FontVApp({super.key, required this.controller, this.ads});
  final FontController controller;
  final AdsController? ads;
  @override
  State<FontVApp> createState() => _FontVAppState();
}

class _FontVAppState extends State<FontVApp> {
  late final AdsController _ads;
  @override
  void initState() {
    super.initState();
    _ads =
        widget.ads ?? AdsController(enabled: !widget.controller.service.isDemo);
    unawaited(widget.controller.initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_ads.start());
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.controller, _ads]),
    builder: (context, _) => MaterialApp(
      title: 'Font V · ToolMoa',
      locale: widget.controller.language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      localeListResolutionCallback: (locales, _) =>
          locales?.firstOrNull?.languageCode == 'ko'
          ? const Locale('ko')
          : const Locale('en'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: widget.controller.skin.color,
          primary: widget.controller.skin.color,
          surface: _canvas,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _text,
          displayColor: _text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          surfaceTintColor: Colors.transparent,
        ),
        dividerColor: _line,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
      home: FontHome(controller: widget.controller, ads: _ads),
    ),
  );
  @override
  void dispose() {
    widget.controller.dispose();
    if (widget.ads == null) _ads.dispose();
    super.dispose();
  }
}

class FontHome extends StatefulWidget {
  const FontHome({super.key, required this.controller, required this.ads});
  final FontController controller;
  final AdsController ads;
  @override
  State<FontHome> createState() => _FontHomeState();
}

class _FontHomeState extends State<FontHome> {
  final _search = TextEditingController();
  final _catalogScroll = ScrollController(keepScrollOffset: false);
  FontFace? _selected;
  FontController get c => widget.controller;

  void _open(FontFace face, bool wide) {
    if (c.selectingForCompare) {
      if (!c.toggleComparison(face.id)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.compareLimit)));
      }
      return;
    }
    if (wide) {
      setState(() => _selected = face);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FontDetail(controller: c, face: face),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final fonts = c.visibleFonts;
    final selected = c.fonts.where((f) => f.id == _selected?.id).firstOrNull;
    final scaffold = Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 24,
        actions: [
          IconButton(
            key: const Key('compare-mode'),
            tooltip: context.l10n.compareSelect,
            onPressed: () => c.setComparisonSelection(!c.selectingForCompare),
            icon: const Icon(Icons.compare_arrows),
          ),
          IconButton(
            key: const Key('collections-page'),
            tooltip: context.l10n.collections,
            onPressed: () async {
              final id = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => CollectionsPage(controller: c),
                ),
              );
              if (id != null) {
                _search.clear();
                c.selectCollection(id);
              }
            },
            icon: const Icon(Icons.folder_outlined),
          ),
          IconButton(
            key: const Key('import-fonts-page'),
            tooltip: context.l10n.importFonts,
            onPressed: () async {
              final face = await Navigator.of(context).push<FontFace>(
                MaterialPageRoute(
                  builder: (_) => ImportedFontsPage(controller: c),
                ),
              );
              if (face != null && context.mounted) {
                c.setComparisonSelection(false);
                _open(face, MediaQuery.sizeOf(context).width >= 900);
              }
            },
            icon: const Icon(Icons.file_open_outlined),
          ),
        ],
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Font V',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              color: c.skin.color,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: c.tab == 2
            ? SettingsPanel(controller: c, ads: widget.ads)
            : Row(
                children: [
                  Expanded(
                    flex: wide ? 5 : 1,
                    child: _catalog(context, wide, fonts),
                  ),
                  if (wide)
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 24, 24),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _line),
                          ),
                          child: selected != null
                              ? FontDetail(
                                  controller: c,
                                  face: selected,
                                  embedded: true,
                                )
                              : _EmptyState(
                                  icon: Icons.text_fields_rounded,
                                  title: context.l10n.chooseFont,
                                  subtitle: context.l10n.chooseFontSubtitle,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.selectingForCompare || c.comparisonIds.isNotEmpty)
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.l10n.compare} · ${c.comparisonIds.length}/4',
                      ),
                    ),
                    FilledButton(
                      key: const Key('open-comparison'),
                      onPressed: c.comparisonFonts.length < 2
                          ? null
                          : () {
                              c.setComparisonSelection(false);
                              Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => ComparisonPage(controller: c),
                                ),
                              );
                            },
                      child: Text(context.l10n.compare),
                    ),
                    IconButton(
                      tooltip: context.l10n.clearSelection,
                      onPressed: c.clearComparison,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          NavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: c.skin.color.withValues(alpha: .12),
            selectedIndex: c.tab,
            onDestinationSelected: (value) {
              _search.clear();
              c.setTab(value);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.text_fields_rounded),
                label: context.l10n.fonts,
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                selectedIcon: Icon(Icons.bookmark_rounded),
                label: context.l10n.favorites,
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_rounded),
                label: context.l10n.settings,
              ),
            ],
          ),
        ],
      ),
    );
    // Scaffold uses this controller for the iOS status bar tap gesture.
    return PrimaryScrollController(controller: _catalogScroll, child: scaffold);
  }

  Widget _catalog(BuildContext context, bool wide, List<FontFace> fonts) {
    return FontCatalog(
      ads: widget.ads,
      controller: c,
      scrollController: _catalogScroll,
      fonts: fonts,
      selectedFontId: wide ? _selected?.id : null,
      onOpen: (face) => _open(face, wide),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 52, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.tab == 1
                      ? context.l10n.collectionKicker
                      : context.l10n.catalogKicker,
                  style: TextStyle(
                    color: c.skin.color,
                    fontSize: 12,
                    letterSpacing: 2.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  c.tab == 1
                      ? context.l10n.collectionHero
                      : context.l10n.catalogHero,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  c.service.isDemo
                      ? context.l10n.browserDemoDescription
                      : context.l10n.catalogSubtitle(
                          c.familyCount,
                          c.fonts.length,
                        ),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                if (c.storageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l10n.storageIssue(c.storageError!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('font-search'),
                  controller: _search,
                  onChanged: c.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchHint,
                    hintStyle: const TextStyle(color: _muted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    suffixIcon: c.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.l10n.clearSearch,
                            onPressed: () {
                              _search.clear();
                              c.setQuery('');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Tooltip(
                      message: c.coverageAvailable
                          ? context.l10n.hangulFilterHelp
                          : context.l10n.deviceFeature,
                      child: FilterChip(
                        key: const Key('hangul-filter'),
                        label: Text(context.l10n.hangulOnly),
                        selected: c.hangulOnly,
                        onSelected: c.coverageAvailable && !c.loading
                            ? (value) async {
                                try {
                                  await c.setHangulOnly(value);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.l10n.coverageError,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                if (c.selectingForCompare)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(context.l10n.compareHint),
                  ),
                if (c.tab == 1 && c.collections.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'collection-filter:${c.selectedCollectionId}',
                      ),
                      initialValue: c.selectedCollectionId ?? '__favorites__',
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: '__favorites__',
                          child: Text(context.l10n.favorites),
                        ),
                        for (final collection in c.collections)
                          DropdownMenuItem(
                            value: collection.id,
                            child: Text(
                              collection.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        _search.clear();
                        c.selectCollection(
                          value == '__favorites__' ? null : value,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      emptyState: c.loading || c.hangulLoading
          ? const Center(child: CircularProgressIndicator())
          : c.error != null
          ? _EmptyState(
              icon: Icons.error_outline,
              title: context.l10n.loadIssue(c.error!),
              action: TextButton(
                onPressed: c.initialize,
                child: Text(context.l10n.retry),
              ),
            )
          : _EmptyState(
              icon: c.query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.bookmark_border_rounded,
              title: c.selectedCollection != null && c.query.isEmpty
                  ? context.l10n.collectionNoFonts
                  : c.query.isNotEmpty || c.hangulOnly
                  ? context.l10n.noMatches
                  : context.l10n.favoritesEmpty,
              subtitle: c.selectedCollection != null && c.query.isEmpty
                  ? context.l10n.collectionAdvice
                  : c.query.isNotEmpty || c.hangulOnly
                  ? context.l10n.searchAdvice
                  : context.l10n.favoritesAdvice,
            ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _catalogScroll.dispose();
    super.dispose();
  }
}

class FontDetail extends StatelessWidget {
  const FontDetail({
    super.key,
    required this.controller,
    required this.face,
    this.embedded = false,
  });
  final FontController controller;
  final FontFace face;
  final bool embedded;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final content = ListView(
        primary: !embedded,
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      face.family.toUpperCase(),
                      style: TextStyle(
                        color: c.skin.color,
                        fontSize: 12,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      face.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      face.style,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: c.favorites.contains(face.id)
                    ? context.l10n.removeFavorite
                    : context.l10n.addFavorite,
                onPressed: () => c.toggleFavorite(face.id),
                icon: Icon(
                  c.favorites.contains(face.id)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: c.skin.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                key: const Key('font-export'),
                onPressed: () => showFontExport(context, c, face),
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(context.l10n.exportImage),
              ),
              OutlinedButton.icon(
                key: const Key('font-collections'),
                onPressed: () => showFontCollections(context, c, face.id),
                icon: const Icon(Icons.folder_outlined, size: 18),
                label: Text(context.l10n.addToCollection),
              ),
              OutlinedButton.icon(
                key: const Key('font-compare'),
                onPressed: () {
                  if (!c.toggleComparison(face.id)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.compareLimit)),
                    );
                  }
                },
                icon: Icon(
                  c.comparisonIds.contains(face.id)
                      ? Icons.check
                      : Icons.compare_arrows,
                  size: 18,
                ),
                label: Text(
                  c.comparisonIds.contains(face.id)
                      ? context.l10n.removeFromCompare
                      : context.l10n.addToCompare,
                ),
              ),
              if (face.imported) Chip(label: Text(context.l10n.importedLabel)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            key: const Key('preview-canvas'),
            height: 320,
            decoration: BoxDecoration(
              color: c.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            padding: const EdgeInsets.all(24),
            child: Semantics(
              label: context.l10n.previewSemantics(face.name, c.sample),
              image: true,
              child: ExcludeSemantics(
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
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _SampleChip(
                label: 'Aa',
                tooltip: context.l10n.sampleEnglish,
                onTap: () => c.setSample(
                  'The quick brown fox\njumps over the lazy dog.\n\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz',
                ),
              ),
              _SampleChip(
                label: '가나다',
                tooltip: context.l10n.sampleKorean,
                onTap: () => c.setSample(
                  '글자마다, 새로운 가능성.\n\n가나다라마바사아자차카타파하\n다람쥐 헌 쳇바퀴에 타고파.',
                ),
              ),
              _SampleChip(
                label: '123',
                tooltip: context.l10n.sampleNumbers,
                onTap: () => c.setSample(
                  '0123456789\n\n! @ # \$ % ^ & * ( )\n+ − × ÷ = ≠ < >',
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 14),
                label: Text(
                  context.l10n.customSample,
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _editSample(context, c),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                context.l10n.fontSize,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${c.size.round()} pt',
                style: TextStyle(
                  color: c.skin.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 12, color: _muted)),
              Expanded(
                child: Slider(
                  key: const Key('font-size'),
                  value: c.size,
                  min: 12,
                  max: 96,
                  divisions: 84,
                  label: '${c.size.round()} pt',
                  semanticFormatterCallback: (value) =>
                      context.l10n.points(value.round()),
                  onChanged: c.setSize,
                ),
              ),
              Text('A', style: TextStyle(fontSize: 23, color: _muted)),
            ],
          ),
          const SizedBox(height: 10),
          TypographyControls(controller: c, includeSize: false),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ColorButton(
                  label: context.l10n.textColor,
                  color: c.ink,
                  onTap: () => pickPreviewColor(context, c, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColorButton(
                  label: context.l10n.backgroundColor,
                  color: c.paper,
                  onTap: () => pickPreviewColor(context, c, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: c.resetPreview,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: Text(
                  context.l10n.resetPreview,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.l10n.copyFontName,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: face.name));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.fontNameCopied)),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.fallbackHelp,
            style: TextStyle(fontSize: 12, height: 1.7, color: _muted),
          ),
          const SizedBox(height: 16),
          CharacterSupportCard(service: c.service, face: face, text: c.sample),
        ],
      );
      if (embedded) return content;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.previewTitle,
            style: TextStyle(fontSize: 15),
          ),
        ),
        body: SafeArea(top: false, child: content),
      );
    },
  );
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, required this.controller, required this.ads});
  final FontController controller;
  final AdsController ads;
  Future<void> _openPage(BuildContext context, String path) async {
    try {
      if (await launchUrl(
        Uri.https('toolmoa.app', path),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      /* Keep settings usable if no browser is available. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.openLinkError)));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        context.l10n.settingsKicker,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          color: controller.skin.color,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n.myFontV,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
      ),
      const SizedBox(height: 32),
      Text(
        context.l10n.language,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        context.l10n.languageDescription,
        style: const TextStyle(fontSize: 12, color: _muted, height: 1.6),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<AppLanguage>(
        key: const Key('app-language'),
        initialValue: controller.language,
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: AppLanguage.system,
            child: Text(
              context.l10n.systemLanguage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
          const DropdownMenuItem(value: AppLanguage.ko, child: Text('한국어')),
        ],
        onChanged: (language) {
          if (language != null) controller.setLanguage(language);
        },
      ),
      const SizedBox(height: 32),
      Text(
        context.l10n.theme,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        context.l10n.themeDescription,
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: FontSkin.values
            .map(
              (skin) => Semantics(
                selected: controller.skin == skin,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  key: ValueKey('skin:${skin.name}'),
                  onTap: () => controller.setSkin(skin),
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: controller.skin == skin ? skin.color : _line,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: skin.color,
                          child: controller.skin == skin
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.skinName(skin),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 36),
      ListTile(
        key: const Key('privacy-policy'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.policy_outlined),
        title: Text(context.l10n.privacyPolicy),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _openPage(context, '/apps/fontv/privacy/'),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.help_outline),
        title: Text(context.l10n.appSupport),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _openPage(context, '/apps/fontv/support/'),
      ),
      if (ads.privacyOptionsRequired)
        ListTile(
          key: const Key('ad-privacy-options'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(context.l10n.adPrivacy),
          onTap: () async {
            final success = await ads.openPrivacyOptions();
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.privacyUnavailable)),
              );
            }
          },
        ),
      const Divider(),
      const SizedBox(height: 24),
      Text(
        context.l10n.aboutTitle,
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n.aboutBody,
        style: TextStyle(fontSize: 12, height: 1.9, color: _muted),
      ),
      const SizedBox(height: 30),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ToolMoa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.9,
                    ),
                  ),
                ),
                Text(
                  'FONT V / 2.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: controller.skin.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Developed by jhoon-dev',
              style: TextStyle(fontSize: 12, height: 1.5, color: _muted),
            ),
          ],
        ),
      ),
      if (controller.service.isDemo)
        Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            context.l10n.browserDemoFooter,
            style: TextStyle(fontSize: 12, color: _muted, height: 1.7),
          ),
        ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .55),
            size: 38,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ),
          ?action,
        ],
      ),
    ),
  );
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: ActionChip(
      onPressed: onTap,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      side: const BorderSide(color: _line),
    ),
  );
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      side: const BorderSide(color: _line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _line),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _text),
          ),
        ),
        const Icon(Icons.expand_more_rounded, size: 16, color: _muted),
      ],
    ),
  );
}

Future<void> _editSample(BuildContext context, FontController c) async {
  final text = TextEditingController(text: c.sample);
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.sampleDialogTitle),
      content: SizedBox(
        width: 440,
        child: TextField(
          key: const Key('sample-input'),
          controller: text,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          decoration: InputDecoration(hintText: context.l10n.sampleInputHint),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, text.text),
          child: Text(context.l10n.apply),
        ),
      ],
    ),
  );
  // The route's exit animation may still reference its editing controller.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  text.dispose();
  if (value != null) c.setSample(value);
}
