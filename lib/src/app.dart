import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller.dart';
import 'font_preview.dart';
import 'font_service.dart';

const _canvas = Color(0xFFF8F7F4);
const _text = Color(0xFF242329);
const _muted = Color(0xFF78767E);
const _line = Color(0xFFE8E5E2);

class FontVApp extends StatefulWidget {
  const FontVApp({super.key, required this.controller});
  final FontController controller;
  @override
  State<FontVApp> createState() => _FontVAppState();
}

class _FontVAppState extends State<FontVApp> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => MaterialApp(
      title: 'Font V · ToolMoa',
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
      home: FontHome(controller: widget.controller),
    ),
  );
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}

class FontHome extends StatefulWidget {
  const FontHome({super.key, required this.controller});
  final FontController controller;
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
        title: Row(
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
            const Text(
              ' V',
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.w300),
            ),
            const SizedBox(width: 14),
            const Flexible(
              child: Text(
                'TOOLMOA',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.9,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c.service.isDemo
                    ? 'DEMO'
                    : defaultTargetPlatform == TargetPlatform.iOS
                    ? 'iOS'
                    : 'ANDROID',
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: c.tab == 2
            ? SettingsPanel(controller: c)
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
                              : const _EmptyState(
                                  icon: Icons.text_fields_rounded,
                                  title: '서체를 골라보세요.',
                                  subtitle: '크기와 색을 바꾸며 글자의 표정을 살펴보세요.',
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.text_fields_rounded),
            label: '폰트',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: '즐겨찾기',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '설정'),
        ],
      ),
    );
  }

  Widget _catalog(BuildContext context, bool wide, List<FontFace> fonts) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.tab == 1
                          ? 'YOUR COLLECTION'
                          : 'A CLOSER LOOK AT LETTERS',
                      style: TextStyle(
                        color: c.skin.color,
                        fontSize: 10,
                        letterSpacing: 2.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.tab == 1 ? '마음에 담은 서체.' : '글자마다,\n새로운 가능성.',
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
                          ? '브라우저 데모 · 실제 기기의 폰트는 모바일 앱에서 확인하세요.'
                          : '${c.familyCount}개 패밀리, ${c.fonts.length}개 서체. 나만의 조합을 찾아보세요.',
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
                          c.storageError!,
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
                        hintText: '폰트 이름, 패밀리 검색',
                        hintStyle: const TextStyle(color: _muted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, size: 21),
                        suffixIcon: c.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '검색 지우기',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Text(
                      c.tab == 1 ? '즐겨찾기' : '모든 서체',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${fonts.length}',
                      style: TextStyle(color: c.skin.color, fontSize: 12),
                    ),
                    const Spacer(),
                    const Text(
                      'A — Z',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (c.loading || c.error != null || fonts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: c.loading
                ? const Center(child: CircularProgressIndicator())
                : c.error != null
                ? _EmptyState(
                    icon: Icons.error_outline,
                    title: c.error!,
                    action: TextButton(
                      onPressed: c.initialize,
                      child: const Text('다시 시도'),
                    ),
                  )
                : _EmptyState(
                    icon: c.query.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.bookmark_border_rounded,
                    title: c.query.isNotEmpty
                        ? '일치하는 서체가 없어요.'
                        : '마음에 드는 서체를 저장해보세요.',
                    subtitle: c.query.isNotEmpty
                        ? '다른 이름이나 패밀리로 검색해보세요.'
                        : '서체 옆의 북마크를 누르면 여기에 모여요.',
                  ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverList.separated(
              itemCount: fonts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FontCard(
                controller: c,
                face: fonts[index],
                selected: wide && _selected?.id == fonts[index].id,
                onTap: () => _open(fonts[index], wide),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}

class _FontCard extends StatelessWidget {
  const _FontCard({
    required this.controller,
    required this.face,
    required this.onTap,
    this.selected = false,
  });
  final FontController controller;
  final FontFace face;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final favorite = c.favorites.contains(face.id);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('font:${face.id}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? c.skin.color : _line),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
          child: Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 72,
                  height: 60,
                  child: FontPreview(
                    service: c.service,
                    face: face,
                    text: 'Ag',
                    size: 40,
                    color: _text,
                    thumbnail: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      face.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      face.style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('favorite:${face.id}'),
                tooltip: favorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                onPressed: () => c.toggleFavorite(face.id),
                icon: Icon(
                  favorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: favorite ? c.skin.color : _muted,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                        fontSize: 10,
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
                tooltip: c.favorites.contains(face.id) ? '즐겨찾기 해제' : '즐겨찾기 추가',
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
              label: '${face.name} 미리보기: ${c.sample}',
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
                tooltip: '영문 샘플',
                onTap: () => c.setSample(
                  'The quick brown fox\njumps over the lazy dog.\n\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz',
                ),
              ),
              _SampleChip(
                label: '가나다',
                tooltip: '한글 샘플',
                onTap: () => c.setSample(
                  '글자마다, 새로운 가능성.\n\n가나다라마바사아자차카타파하\n다람쥐 헌 쳇바퀴에 타고파.',
                ),
              ),
              _SampleChip(
                label: '123',
                tooltip: '숫자 샘플',
                onTap: () => c.setSample(
                  '0123456789\n\n! @ # \$ % ^ & * ( )\n+ − × ÷ = ≠ < >',
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('직접 입력', style: TextStyle(fontSize: 11)),
                onPressed: () => _editSample(context, c),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                '글자 크기',
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
              const Text('A', style: TextStyle(fontSize: 12, color: _muted)),
              Expanded(
                child: Slider(
                  key: const Key('font-size'),
                  value: c.size,
                  min: 12,
                  max: 96,
                  divisions: 84,
                  label: '${c.size.round()} pt',
                  semanticFormatterCallback: (value) => '${value.round()} 포인트',
                  onChanged: c.setSize,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 23, color: _muted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ColorButton(
                  label: '글자색',
                  color: c.ink,
                  onTap: () => _pickColor(context, c, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColorButton(
                  label: '배경색',
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
                label: const Text('크기·색상 초기화', style: TextStyle(fontSize: 11)),
              ),
              const Spacer(),
              IconButton(
                tooltip: '폰트 이름 복사',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: face.name));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('폰트 이름을 복사했어요.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '지원하지 않는 글자는 기기의 대체 폰트로 표시될 수 있어요.\n긴 문장은 미리보기 영역 밖에서 잘릴 수 있어요.',
            style: TextStyle(fontSize: 10, height: 1.7, color: _muted),
          ),
        ],
      );
      if (embedded) return content;
      return Scaffold(
        appBar: AppBar(
          title: const Text('서체 미리보기', style: TextStyle(fontSize: 15)),
        ),
        body: SafeArea(top: false, child: content),
      );
    },
  );
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, required this.controller});
  final FontController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'MAKE IT YOURS',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          color: controller.skin.color,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '나의 Font V.',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
      ),
      const SizedBox(height: 32),
      const Text(
        '테마',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text(
        '오래전의 다섯 가지 색, 오늘의 새로운 모습.',
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
                        Text(skin.label, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 36),
      const Divider(),
      const SizedBox(height: 24),
      const Text(
        '글자를 탐색하는 작은 도구.',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      const Text(
        'Font V는 기기에 있는 서체를 살펴보고, 크기와 색을 바꿔보는 앱입니다. '
        '기기의 시스템 폰트를 설치하거나 변경하지 않습니다.\n\n'
        '즐겨찾기와 설정은 이 기기에만 저장됩니다. 계정, 광고, 분석 추적 없이 오프라인으로 사용할 수 있습니다. '
        'iOS와 Android의 폰트 목록은 기기와 OS 버전에 따라 다릅니다.',
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
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: controller.skin.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 12,
                  color: controller.skin.color,
                ),
                const SizedBox(width: 7),
                const Flexible(
                  child: Text(
                    'Made with care by ToolMoa.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: _text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Developed by jhoon-dev',
              style: TextStyle(fontSize: 11, height: 1.5, color: _muted),
            ),
          ],
        ),
      ),
      if (controller.service.isDemo)
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '브라우저에서는 3가지 데모 서체만 제공합니다. 실제 시스템 폰트 열람은 iOS·Android 앱에서 지원합니다.',
            style: TextStyle(fontSize: 11, color: _muted, height: 1.7),
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
      label: Text(label, style: const TextStyle(fontSize: 11)),
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
            style: const TextStyle(fontSize: 11, color: _text),
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
      title: const Text('나만의 미리보기 문장'),
      content: SizedBox(
        width: 440,
        child: TextField(
          key: const Key('sample-input'),
          controller: text,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: '여기에 문장을 입력하세요.'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, text.text),
          child: const Text('적용'),
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
      title: foreground ? '글자색' : '배경색',
    ),
  );
  if (color != null) {
    foreground ? c.setInk(color) : c.setPaper(color);
  }
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.initial, required this.title});
  final Color initial;
  final String title;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late Color color = widget.initial;
  late final hex = TextEditingController(text: _hex(color));
  String? error;
  static String _hex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  void change(Color next) {
    setState(() {
      color = next;
      hex.text = _hex(next);
      error = null;
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
              widget.title,
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
                errorText: error,
              ),
              onChanged: (value) => setState(() {
                if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
                  color = Color(0xFF000000 | int.parse(value, radix: 16));
                  error = null;
                } else {
                  error = '6자리 색상 코드를 입력하세요.';
                }
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: error == null
                    ? () => Navigator.pop(context, color)
                    : null,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('적용'),
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
