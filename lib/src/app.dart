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
  FontFace? _selected;
  FontController get c => widget.controller;

  void _open(FontFace face, bool wide) {
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 24,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'font',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.8,
                  color: c.skin.color,
                ),
              ),
              Text(
                ' V',
                style: TextStyle(fontSize: 29, fontWeight: FontWeight.w300),
              ),
              const SizedBox(width: 14),
              Text(
                'TOOLMOA',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.9,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
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
                          child: _selected != null
                              ? FontDetail(
                                  controller: c,
                                  face: _selected!,
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
      bottomNavigationBar: NavigationBar(
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
    );
  }

  Widget _catalog(BuildContext context, bool wide, List<FontFace> fonts) {
    return FontCatalog(
      ads: widget.ads,
      controller: c,
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
              ],
            ),
          ),
        ],
      ),
      emptyState: c.loading
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
              title: c.query.isNotEmpty
                  ? context.l10n.noMatches
                  : context.l10n.favoritesEmpty,
              subtitle: c.query.isNotEmpty
                  ? context.l10n.searchAdvice
                  : context.l10n.favoritesAdvice,
            ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
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
          Row(
            children: [
              Expanded(
                child: _ColorButton(
                  label: context.l10n.textColor,
                  color: c.ink,
                  onTap: () => _pickColor(context, c, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColorButton(
                  label: context.l10n.backgroundColor,
                  color: c.paper,
                  onTap: () => _pickColor(context, c, false),
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

Future<void> _pickColor(
  BuildContext context,
  FontController c,
  bool foreground,
) async {
  final color = await showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ColorPicker(
      initial: foreground ? c.ink : c.paper,
      foreground: foreground,
    ),
  );
  if (color != null) {
    foreground ? c.setInk(color) : c.setPaper(color);
  }
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.initial, required this.foreground});
  final Color initial;
  final bool foreground;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late Color color = widget.initial;
  late final hex = TextEditingController(text: _hex(color));
  bool invalid = false;
  static String _hex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  void change(Color next) {
    setState(() {
      color = next;
      hex.text = _hex(next);
      invalid = false;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.foreground
                  ? context.l10n.textColor
                  : context.l10n.backgroundColor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  const [
                        0xFF252329,
                        0xFFFFFFFF,
                        0xFFFFFBF5,
                        0xFFD9437B,
                        0xFFCC4149,
                        0xFF28745B,
                        0xFF896344,
                        0xFF7655AB,
                        0xFF467EB5,
                      ]
                      .map(
                        (argb) => Semantics(
                          label: '#${argb.toRadixString(16).substring(2)}',
                          button: true,
                          child: InkWell(
                            onTap: () => change(Color(argb)),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(argb),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _muted.withValues(alpha: .3),
                                ),
                              ),
                              child: color.toARGB32() == argb
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Color(argb).computeLuminance() > .5
                                          ? Colors.black
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            for (final channel in ['R', 'G', 'B'])
              Row(
                children: [
                  SizedBox(width: 20, child: Text(channel)),
                  Expanded(
                    child: Slider(
                      value: switch (channel) {
                        'R' => color.r * 255,
                        'G' => color.g * 255,
                        _ => color.b * 255,
                      },
                      min: 0,
                      max: 255,
                      divisions: 255,
                      label: switch (channel) {
                        'R' => '${(color.r * 255).round()}',
                        'G' => '${(color.g * 255).round()}',
                        _ => '${(color.b * 255).round()}',
                      },
                      onChanged: (value) => change(
                        Color.fromARGB(
                          255,
                          channel == 'R'
                              ? value.round()
                              : (color.r * 255).round(),
                          channel == 'G'
                              ? value.round()
                              : (color.g * 255).round(),
                          channel == 'B'
                              ? value.round()
                              : (color.b * 255).round(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: hex,
              maxLength: 6,
              decoration: InputDecoration(
                prefixText: '# ',
                labelText: 'HEX',
                errorText: invalid ? context.l10n.invalidHex : null,
              ),
              onChanged: (value) => setState(() {
                if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
                  color = Color(0xFF000000 | int.parse(value, radix: 16));
                  invalid = false;
                } else {
                  invalid = true;
                }
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !invalid
                    ? () => Navigator.pop(context, color)
                    : null,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(context.l10n.apply),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }
}
