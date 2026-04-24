// Category add/edit modal sheet (plan §6, §12 risks #2 & #5).
//
// - Fields: display name, icon, color, type (segmented control).
// - Type toggle is disabled in Edit mode with
//   `categoriesFormTypeLockedHint` visible beneath (plan §12 risk #2).
// - Save enabled when display-name non-empty AND icon selected.
// - Color defaults to palette index 0 when the user never opens the
//   color picker.
// - Wrapped in `SingleChildScrollView` so the soft keyboard does not
//   clip the body (plan §12 risk #5).
// - Typed repository exceptions
//   (`CategoryTypeLockedException`, `CategoryInUseException`) surface
//   inline as an error banner — the sheet stays open for retry.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../categories_controller.dart';
import 'category_color_picker.dart';
import 'category_display.dart';
import 'category_icon_picker.dart';

Future<void> showCategoryFormSheet(
  BuildContext context, {
  Category? initial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _CategoryFormSheet(initial: initial),
    ),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({this.initial});

  final Category? initial;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  String? _icon;
  int _color = 0;
  CategoryType _type = CategoryType.expense;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl = TextEditingController(
      text: initial == null
          ? ''
          // If the row is seeded (`l10nKey != null`) and has no custom
          // rename yet, default to the currently-displayed localized
          // name so users renaming a seed see the live value instead of
          // blank.
          : (initial.customName ?? ''),
    );
    if (initial != null) {
      _icon = initial.icon;
      _color = initial.color;
      _type = initial.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && _nameCtrl.text.trim().isNotEmpty && _icon != null;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _icon == null) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(categoriesControllerProvider.notifier);
      final initial = widget.initial;
      if (initial == null) {
        await notifier.createCategory(
          Category(
            id: 0,
            icon: _icon!,
            color: _color,
            type: _type,
            customName: name,
          ),
        );
      } else {
        // Rename + icon/color. Type is locked in Edit mode and cannot
        // have changed here.
        if ((initial.customName ?? '') != name) {
          await notifier.renameCategory(initial.id, name);
        }
        if (initial.icon != _icon || initial.color != _color) {
          await notifier.updateIconColor(
            id: initial.id,
            icon: _icon!,
            color: _color,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on CategoryTypeLockedException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _saving = false;
      });
    } on CategoryInUseException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = l10n.errorSnackbarGeneric;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEdit
                  ? categoryDisplayName(widget.initial!, l10n)
                  : l10n.categoriesAddCta,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.categoriesFormNameLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _FieldHeader(label: l10n.categoriesFormIconLabel),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: Icon(iconForKey(_icon)),
              label: Text(_icon ?? '—'),
              onPressed: () async {
                final key = await showCategoryIconPicker(
                  context,
                  selected: _icon,
                );
                if (key != null) setState(() => _icon = key);
              },
            ),
            const SizedBox(height: 16),
            _FieldHeader(label: l10n.categoriesFormColorLabel),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final idx = await showCategoryColorPicker(
                  context,
                  selectedIndex: _color,
                );
                if (idx != null) setState(() => _color = idx);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorForIndex(_color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldHeader(label: l10n.categoriesFormTypeLabel),
            const SizedBox(height: 4),
            SegmentedButton<CategoryType>(
              segments: [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(l10n.transactionTypeExpense),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(l10n.transactionTypeIncome),
                ),
              ],
              selected: {_type},
              // Disable segmented control in Edit mode — category type
              // is immutable after first use (plan §12 risk #2). The
              // repository enforces this too; we disable the UI so
              // users never hit the exception path for that reason.
              onSelectionChanged: _isEdit
                  ? null
                  : (set) => setState(() => _type = set.first),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 4),
              Text(
                l10n.categoriesFormTypeLockedHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(l10n.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldHeader extends StatelessWidget {
  const _FieldHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall,
  );
}
