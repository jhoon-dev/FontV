import 'package:flutter/material.dart';
import 'controller.dart';
import 'font_collection.dart';
import 'localization.dart';

Future<String?> editCollectionName(
  BuildContext context,
  FontController controller, {
  FontCollection? collection,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _CollectionNameDialog(controller: controller, collection: collection),
);

class _CollectionNameDialog extends StatefulWidget {
  const _CollectionNameDialog({required this.controller, this.collection});
  final FontController controller;
  final FontCollection? collection;
  @override
  State<_CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<_CollectionNameDialog> {
  late final _text = TextEditingController(text: widget.collection?.name ?? '');
  bool _invalid = false;
  void _submit() {
    final name = _text.text.trim();
    if (name.isEmpty ||
        name.length > 40 ||
        widget.controller.collections.any(
          (x) =>
              x.id != widget.collection?.id &&
              x.name.toLowerCase() == name.toLowerCase(),
        )) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.collection == null
          ? context.l10n.newCollection
          : context.l10n.rename,
    ),
    content: SizedBox(
      width: 380,
      child: TextField(
        key: const Key('collection-name'),
        controller: _text,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(
          labelText: context.l10n.collectionName,
          errorText: _invalid ? context.l10n.collectionNameHelp : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(onPressed: _submit, child: Text(context.l10n.apply)),
    ],
  );
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key, required this.controller});
  final FontController controller;
  Future<void> _create(BuildContext context) async {
    final name = await editCollectionName(context, controller);
    if (name != null) controller.createCollection(name);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.collections)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-collection'),
        onPressed: () => _create(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: Text(context.l10n.newCollection),
      ),
      body: SafeArea(
        child: controller.collections.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(context.l10n.collectionEmpty),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  for (final collection in controller.collections)
                    Card.outlined(
                      child: ListTile(
                        key: ValueKey('collection:${collection.id}'),
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(collection.name),
                        subtitle: Text(
                          '${collection.fontIds.where((id) => controller.fonts.any((f) => f.id == id)).length} ${context.l10n.fontsUnit}',
                        ),
                        onTap: () => Navigator.pop(context, collection.id),
                        trailing: PopupMenuButton<String>(
                          tooltip: context.l10n.collectionManage,
                          onSelected: (action) async {
                            if (action == 'rename') {
                              final name = await editCollectionName(
                                context,
                                controller,
                                collection: collection,
                              );
                              if (name != null) {
                                controller.renameCollection(
                                  collection.id,
                                  name,
                                );
                              }
                            } else {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    context.l10n.deleteCollectionTitle,
                                  ),
                                  content: Text(
                                    context.l10n.deleteCollectionBody,
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
                              if (confirmed == true) {
                                controller.deleteCollection(collection.id);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(context.l10n.rename),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    ),
  );
}

Future<void> showFontCollections(
  BuildContext context,
  FontController controller,
  String fontId,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.addToCollection,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(context.l10n.collectionChoose),
              const SizedBox(height: 12),
              Expanded(
                child: controller.collections.isEmpty
                    ? Center(child: Text(context.l10n.collectionEmpty))
                    : ListView(
                        children: [
                          for (final collection in controller.collections)
                            CheckboxListTile(
                              key: ValueKey('membership:${collection.id}'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(collection.name),
                              value: collection.fontIds.contains(fontId),
                              onChanged: (value) =>
                                  controller.setCollectionMembership(
                                    collection.id,
                                    fontId,
                                    value == true,
                                  ),
                            ),
                        ],
                      ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final name = await editCollectionName(context, controller);
                  if (name != null) {
                    final id = controller.createCollection(name);
                    if (id != null) {
                      controller.setCollectionMembership(id, fontId, true);
                    }
                  }
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(context.l10n.newCollection),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(context.l10n.done),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
