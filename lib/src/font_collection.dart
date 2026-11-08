class FontCollection {
  FontCollection({
    required this.id,
    required this.name,
    Iterable<String> fontIds = const [],
  }) : fontIds = Set.unmodifiable(fontIds);
  final String id;
  final String name;
  final Set<String> fontIds;

  FontCollection copyWith({String? name, Iterable<String>? fontIds}) =>
      FontCollection(
        id: id,
        name: name ?? this.name,
        fontIds: fontIds ?? this.fontIds,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'fontIds': fontIds.toList()..sort(),
  };

  static FontCollection? fromJson(Object? value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['name'] is! String ||
        value['fontIds'] is! List) {
      return null;
    }
    final name = (value['name'] as String).trim();
    if (name.isEmpty || name.length > 40 || (value['id'] as String).isEmpty) {
      return null;
    }
    return FontCollection(
      id: value['id'] as String,
      name: name,
      fontIds: (value['fontIds'] as List).whereType<String>(),
    );
  }
}
