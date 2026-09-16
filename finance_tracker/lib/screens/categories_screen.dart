import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../database/category_dao.dart';
import '../database/reports_dao.dart';
import '../models/category.dart';
import '../widgets/money.dart';

/// Manage spending categories, with the total spent against each one.
///
/// The list comes from [ReportsDao.getTotalsByCategory], which LEFT JOINs the
/// expenses, so a category with no spending still appears (at $0.00) instead
/// of vanishing from the screen you would use to delete it.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.categoryDao,
    required this.reportsDao,
  });

  final CategoryDao categoryDao;
  final ReportsDao reportsDao;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<CategoryTotal>> _totals = widget.reportsDao.getTotalsByCategory();

  /// Re-runs the query. Every mutation ends here rather than patching the
  /// in-memory list, so what is on screen always came from the database.
  void _reload() {
    setState(() {
      _totals = widget.reportsDao.getTotalsByCategory();
    });
  }

  Future<void> _create() async {
    final draft = await showDialog<Category>(
      context: context,
      builder: (context) => const _CategoryEditor(title: 'New category'),
    );
    if (draft == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.categoryDao.insertCategory(draft);
    } on DatabaseException catch (_) {
      // `name` is UNIQUE in the schema, and the DAO inserts with
      // ConflictAlgorithm.abort, so a duplicate name lands here.
      messenger.showSnackBar(
        SnackBar(content: Text('There is already a category called "${draft.name}".')),
      );
      return;
    }
    if (mounted) {
      _reload();
    }
  }

  Future<void> _edit(CategoryTotal existing) async {
    final draft = await showDialog<Category>(
      context: context,
      builder: (context) => _CategoryEditor(
        title: 'Edit category',
        initialName: existing.categoryName,
        initialType: existing.categoryType,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      // The editor dialog does not know the row id, so it is reattached here.
      await widget.categoryDao.updateCategory(draft.copyWith(id: existing.categoryId));
    } on DatabaseException catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('There is already a category called "${draft.name}".')),
      );
      return;
    }
    if (mounted) {
      _reload();
    }
  }

  Future<void> _delete(CategoryTotal target) async {
    final messenger = ScaffoldMessenger.of(context);

    // Ask the database before offering to delete anything. A category with
    // expenses behind it must never be removed: doing so would take the user's
    // spending history for that category with it. The schema's ON DELETE
    // RESTRICT would refuse anyway, but a foreign-key exception is not an
    // explanation — this is.
    final inUse = await widget.categoryDao.isCategoryInUse(target.categoryId);
    if (!mounted) {
      return;
    }
    if (inUse) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${target.categoryName}" — it still has expenses '
            'recorded against it. Move or delete those expenses first.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${target.categoryName}"?'),
        content: const Text('This category has no expenses, so nothing else is affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.categoryDao.deleteCategory(target.categoryId);
    } on DatabaseException catch (_) {
      // Backstop for the gap between the check above and this delete: an
      // expense could have been recorded in between. The schema still refuses,
      // and the user gets the same explanation rather than a crash.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${target.categoryName}" — expenses were recorded '
            'against it while this screen was open.',
          ),
        ),
      );
      return;
    }
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: 'New category',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CategoryTotal>>(
        future: _totals,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load categories: ${snapshot.error}'));
          }

          final totals = snapshot.data ?? const <CategoryTotal>[];
          if (totals.isEmpty) {
            return const Center(child: Text('No categories yet.'));
          }

          return ListView.separated(
            itemCount: totals.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final total = totals[index];
              return ListTile(
                title: Text(total.categoryName),
                subtitle: Text(
                  total.categoryType == CategoryType.necessary
                      ? 'Necessary'
                      : 'Discretionary',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatMoney(total.total)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit ${total.categoryName}',
                      onPressed: () => _edit(total),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete ${total.categoryName}',
                      onPressed: () => _delete(total),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Name + type dialog, used for both create and edit.
///
/// Returns a [Category] with no id: the caller reattaches the id when editing,
/// because the dialog has no business knowing about row identity.
class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({
    required this.title,
    this.initialName,
    this.initialType,
  });

  final String title;
  final String? initialName;
  final CategoryType? initialType;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName ?? '');
  late CategoryType _type = widget.initialType ?? CategoryType.necessary;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      Category(name: _nameController.text.trim(), type: _type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: CategoryType.necessary,
                  child: Text('Necessary'),
                ),
                DropdownMenuItem(
                  value: CategoryType.discretionary,
                  child: Text('Discretionary'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _type = value ?? CategoryType.necessary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
