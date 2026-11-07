import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'controller.dart';
import 'font_catalog_model.dart';
import 'font_preview.dart';
import 'font_service.dart';
import 'localization.dart';
import 'ads.dart';

const _ink = Color(0xFF242329);
const _muted = Color(0xFF78767E);
const _line = Color(0xFFE8E5E2);

class FontCatalog extends StatefulWidget {
  const FontCatalog({
    super.key,
    required this.controller,
    required this.fonts,
    required this.header,
    required this.emptyState,
    required this.onOpen,
    this.selectedFontId,
    this.ads,
  });
  final FontController controller;
  final List<FontFace> fonts;
  final Widget header;
  final Widget emptyState;
  final ValueChanged<FontFace> onOpen;
  final String? selectedFontId;
  final AdsController? ads;

  @override
  State<FontCatalog> createState() => _FontCatalogState();
}

class _FontCatalogState extends State<FontCatalog> {
  final _scroll = ScrollController(keepScrollOffset: false);
  final _headerKey = GlobalKey();
  final _expanded = <String>{};
  final _collapsedSearch = <String>{};
  final _sectionRows = <String, int>{};
  List<_CatalogRow> _rows = [];
  List<double> _rowOffsets = [];
  double _rowExtent = 108;
  String? _activeLabel;
  bool _scrubbing = false;
  late String _lastQuery;
  late int _lastTab;
  int _filterGeneration = 0;

  bool get _searching => widget.controller.query.trim().isNotEmpty;
  double get _headerHeight {
    final box = _headerKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  @override
  void initState() {
    super.initState();
    _lastQuery = widget.controller.query;
    _lastTab = widget.controller.tab;
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant FontCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastQuery != widget.controller.query ||
        _lastTab != widget.controller.tab) {
      _lastQuery = widget.controller.query;
      _lastTab = widget.controller.tab;
      _collapsedSearch.clear();
      _activeLabel = null;
      _scrubbing = false;
      final generation = ++_filterGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _filterGeneration && _scroll.hasClients) {
          _scroll.jumpTo(0);
        }
      });
    }
  }

  bool _isExpanded(FontFamilyGroup group) => _searching
      ? !_collapsedSearch.contains(group.family)
      : _expanded.contains(group.family);

  void _toggle(FontFamilyGroup group) => setState(() {
    final set = _searching ? _collapsedSearch : _expanded;
    if (!set.remove(group.family)) set.add(group.family);
  });

  void _toggleAll(List<FontFamilyGroup> groups, bool expanded) => setState(() {
    for (final group in groups) {
      if (_searching) {
        expanded
            ? _collapsedSearch.add(group.family)
            : _collapsedSearch.remove(group.family);
      } else {
        expanded ? _expanded.remove(group.family) : _expanded.add(group.family);
      }
    }
  });

  void _onScroll() {
    if (!_scroll.hasClients || _rows.isEmpty || _scrubbing) return;
    final offset = _scroll.offset - _headerHeight;
    var index = 0;
    for (var i = 1; i < _rowOffsets.length; i++) {
      if (_rowOffsets[i] > offset) break;
      index = i;
    }
    final label = _rows[index].group.indexLabel;
    if (_activeLabel != label && mounted) setState(() => _activeLabel = label);
  }

  void _jumpTo(String label) {
    final index = _sectionRows[label];
    if (index == null || !_scroll.hasClients) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _activeLabel = label;
      _scrubbing = true;
    });
    // Prefix offsets include text-scaled font rows and taller ad cards.
    _scroll.jumpTo(
      (_headerHeight + _rowOffsets[index]).clamp(
        0,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  void _endScrub() {
    if (_scrubbing) setState(() => _scrubbing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final groups = groupFontFamilies(widget.fonts);
    final expandable = groups.where((group) => group.faces.length > 1).toList();
    final allExpanded = expandable.isNotEmpty && expandable.every(_isExpanded);
    final scaler = MediaQuery.textScalerOf(context);
    final adExtent = NativeAdCard.extent(scaler) + 10;
    final showAds =
        c.tab == 0 &&
        !_searching &&
        widget.ads?.canShowAds == true &&
        MediaQuery.sizeOf(context).width >= 372;
    _rowExtent = math.max(
      108,
      44 +
          math.max(60, scaler.scale(15) * 2 * 1.4 + scaler.scale(12) * 1.4 + 6),
    );
    _rows = [];
    _sectionRows.clear();
    for (final (groupIndex, group) in groups.indexed) {
      _sectionRows.putIfAbsent(group.indexLabel, () => _rows.length);
      if (group.faces.length == 1) {
        _rows.add(_CatalogRow(group, group.faces.single));
      } else {
        _rows.add(_CatalogRow(group, null));
        if (_isExpanded(group)) {
          _rows.addAll(
            group.faces.map((face) => _CatalogRow(group, face, nested: true)),
          );
        }
      }
      if (showAds &&
          (groupIndex + 1) % 8 == 0 &&
          groupIndex + 1 < groups.length) {
        final slot = (groupIndex + 1) ~/ 8;
        if (widget.ads!.showSlot(slot)) {
          _rows.add(_CatalogRow(group, null, adSlot: slot));
        }
      }
    }
    _rowOffsets = [];
    var rowOffset = 0.0;
    for (final row in _rows) {
      _rowOffsets.add(rowOffset);
      rowOffset += row.adSlot != null ? adExtent : _rowExtent;
    }
    final labels = _sectionRows.keys.toList();
    final active = labels.contains(_activeLabel)
        ? _activeLabel
        : labels.firstOrNull;
    return Stack(
      children: [
        CustomScrollView(
          key: const Key('font-catalog-scroll'),
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                key: _headerKey,
                children: [
                  widget.header,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 52, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: c.tab == 1
                                      ? '${context.l10n.favorites}  '
                                      : '${context.l10n.families}  ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                TextSpan(
                                  text: context.l10n.catalogCounts(
                                    groups.length,
                                    widget.fonts.length,
                                  ),
                                  style: TextStyle(color: c.skin.color),
                                ),
                              ],
                            ),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                          ),
                        ),
                        if (expandable.isNotEmpty)
                          TextButton(
                            key: const Key('toggle-all-families'),
                            onPressed: () =>
                                _toggleAll(expandable, allExpanded),
                            child: Text(
                              allExpanded
                                  ? context.l10n.collapseAll
                                  : context.l10n.expandAll,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (c.loading || c.error != null || _rows.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: widget.emptyState,
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverVariedExtentList(
                  itemExtentBuilder: (index, _) => index < _rows.length
                      ? (_rows[index].adSlot != null ? adExtent : _rowExtent)
                      : null,
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final row = _rows[index];
                    if (row.adSlot != null) {
                      return Padding(
                        key: ValueKey('ad-slot:${row.adSlot}'),
                        padding: const EdgeInsets.fromLTRB(8, 0, 44, 10),
                        child: widget.ads!.buildSlot(context, row.adSlot!),
                      );
                    }
                    final card = row.face == null
                        ? _FamilyCard(
                            controller: c,
                            group: row.group,
                            expanded: _isExpanded(row.group),
                            onTap: () => _toggle(row.group),
                          )
                        : _FontCard(
                            controller: c,
                            face: row.face!,
                            selected: widget.selectedFontId == row.face!.id,
                            nested: row.nested,
                            onTap: () => widget.onOpen(row.face!),
                          );
                    return Padding(
                      padding: const EdgeInsets.only(left: 24, right: 52),
                      child: Stack(
                        children: [
                          if (row.nested) ...[
                            Positioned(
                              left: 10,
                              top: 0,
                              width: 2,
                              bottom: row.face!.id == row.group.faces.last.id
                                  ? _rowExtent / 2
                                  : 0,
                              child: ColoredBox(
                                color: c.skin.color.withValues(alpha: .28),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              top: (_rowExtent - 10) / 2,
                              width: 14,
                              height: 2,
                              child: ColoredBox(
                                color: c.skin.color.withValues(alpha: .28),
                              ),
                            ),
                          ],
                          Padding(
                            padding: EdgeInsets.only(
                              left: row.nested ? 24 : 0,
                              bottom: 10,
                            ),
                            child: SizedBox(
                              height: _rowExtent - 10,
                              child: card,
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: _rows.length),
                ),
              ),
          ],
        ),
        if (!c.loading && c.error == null && labels.isNotEmpty)
          Positioned(
            right: 0,
            width: 44,
            top: 8,
            bottom: 8,
            child: _AlphabetIndex(
              labels: labels,
              active: active,
              color: c.skin.color,
              onSelect: _jumpTo,
              onEnd: _endScrub,
            ),
          ),
        if (_scrubbing && active != null)
          Positioned(
            right: 58,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.skin.color,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .12),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Text(
                    active,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}

class _CatalogRow {
  const _CatalogRow(this.group, this.face, {this.nested = false, this.adSlot});
  final FontFamilyGroup group;
  final FontFace? face;
  final bool nested;
  final int? adSlot;
}

class _AlphabetIndex extends StatelessWidget {
  const _AlphabetIndex({
    required this.labels,
    required this.active,
    required this.color,
    required this.onSelect,
    required this.onEnd,
  });
  final List<String> labels;
  final String? active;
  final Color color;
  final ValueChanged<String> onSelect;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final height = math.min(bounds.maxHeight, labels.length * 20.0);
      void select(double y) => onSelect(
        labels[(y / height * labels.length).floor().clamp(
          0,
          labels.length - 1,
        )],
      );
      return Center(
        child: SizedBox(
          width: 44,
          height: height,
          child: GestureDetector(
            key: const Key('font-fast-index'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => select(details.localPosition.dy),
            onTapUp: (_) => onEnd(),
            onTapCancel: onEnd,
            onVerticalDragStart: (details) => select(details.localPosition.dy),
            onVerticalDragUpdate: (details) => select(details.localPosition.dy),
            onVerticalDragEnd: (_) => onEnd(),
            onVerticalDragCancel: onEnd,
            child: Column(
              children: [
                for (final label in labels)
                  Expanded(
                    child: Semantics(
                      key: ValueKey('font-index:$label'),
                      button: true,
                      selected: active == label,
                      label: context.l10n.indexJump(label),
                      onTap: () {
                        onSelect(label);
                        onEnd();
                      },
                      child: ExcludeSemantics(
                        child: Center(
                          child: Container(
                            width: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active == label
                                  ? color.withValues(alpha: .12)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: active == label
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.controller,
    required this.group,
    required this.expanded,
    required this.onTap,
  });
  final FontController controller;
  final FontFamilyGroup group;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.familySemantics(
      group.family,
      group.faces.length,
      expanded ? context.l10n.collapse : context.l10n.expand,
    ),
    child: Material(
      color: controller.skin.color.withValues(alpha: expanded ? .12 : .07),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('family:${group.family}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: expanded
                  ? controller.skin.color.withValues(alpha: .5)
                  : controller.skin.color.withValues(alpha: .2),
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.folder_open_rounded
                      : Icons.folder_copy_rounded,
                  size: 28,
                  color: controller.skin.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.family,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.familyStyles(
                          group.faces.length,
                          group.faces.map((f) => f.style).join(' · '),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: controller.skin.color,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FontCard extends StatelessWidget {
  const _FontCard({
    required this.controller,
    required this.face,
    required this.onTap,
    this.selected = false,
    this.nested = false,
  });
  final FontController controller;
  final FontFace face;
  final VoidCallback onTap;
  final bool selected;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final favorite = controller.favorites.contains(face.id);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(nested ? 12 : 18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('font:${face.id}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(nested ? 12 : 18),
            border: Border.all(color: selected ? controller.skin.color : _line),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: nested ? 44 : 56,
                  height: 60,
                  child: FontPreview(
                    service: controller.service,
                    face: face,
                    text: 'Ag',
                    size: 34,
                    color: _ink,
                    thumbnail: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nested ? face.style : face.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nested ? face.name : face.style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('favorite:${face.id}'),
                tooltip: favorite
                    ? context.l10n.removeFavorite
                    : context.l10n.addFavorite,
                onPressed: () => controller.toggleFavorite(face.id),
                icon: Icon(
                  favorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: favorite ? controller.skin.color : _muted,
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
