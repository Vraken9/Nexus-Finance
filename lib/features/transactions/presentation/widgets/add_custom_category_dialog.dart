import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_finance/core/constants/app_strings.dart';
import 'package:nexus_finance/core/theme/app_colors.dart';
import 'package:nexus_finance/core/theme/app_text_styles.dart';
import 'package:nexus_finance/shared/providers/repository_providers.dart';
import 'package:nexus_finance/shared/widgets/custom_button.dart';

// Popular icon choices for transactions
const _iconChoices = [
  (icon: Icons.shopping_bag, codePoint: 0xe59c),
  (icon: Icons.restaurant, codePoint: 0xe533),
  (icon: Icons.directions_car, codePoint: 0xe531),
  (icon: Icons.home, codePoint: 0xe88a),
  (icon: Icons.flight, codePoint: 0xe541),
  (icon: Icons.favorite, codePoint: 0xe40d),
  (icon: Icons.fitness_center, codePoint: 0xe545),
  (icon: Icons.movie, codePoint: 0xe01d),
];

// Popular colors
const _colorChoices = [
  ('F43F5E', 'Rose'),
  ('F59E0B', 'Amber'),
  ('10B981', 'Emerald'),
  ('3B82F6', 'Blue'),
  ('8B5CF6', 'Purple'),
  ('EC4899', 'Pink'),
  ('EF4444', 'Red'),
  ('6366F1', 'Indigo'),
];

/// Dialog for creating a custom transaction category.
class AddCustomCategoryDialog extends ConsumerStatefulWidget {
  const AddCustomCategoryDialog({
    super.key,
    required this.type, // 'income' | 'expense'
    required this.onCategoryAdded,
  });

  final String type;
  final Function(String categoryUuid) onCategoryAdded;

  @override
  ConsumerState<AddCustomCategoryDialog> createState() =>
      _AddCustomCategoryDialogState();
}

class _AddCustomCategoryDialogState
    extends ConsumerState<AddCustomCategoryDialog> {
  late final TextEditingController _nameCtrl;
  late int _selectedIconCodePoint;
  late String _selectedColorHex;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _selectedIconCodePoint = 0xe3af; // Icons.category
    _selectedColorHex = widget.type == 'income' ? '10B981' : 'F43F5E';
    _isLoading = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama kategori harus diisi')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final uuid = await categoryRepo.createCustomCategory(
        name: name,
        type: widget.type,
        iconCodePoint: _selectedIconCodePoint,
        colorHex: _selectedColorHex,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCategoryAdded(uuid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.categoryAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.categoryError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.addCustomCategory,
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 20),

              // ── Name Input ────────────────────────────────────────────
              Text(
                AppStrings.categoryName,
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Icon Selection ────────────────────────────────────────
              Text(
                AppStrings.selectIcon,
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconChoices.map((choice) {
                  final isSelected = _selectedIconCodePoint == choice.codePoint;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIconCodePoint = choice.codePoint),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        choice.icon,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Color Selection ───────────────────────────────────────
              Text(
                AppStrings.selectColor,
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _colorChoices.map((choice) {
                  final isSelected = _selectedColorHex == choice.$1;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColorHex = choice.$1),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${choice.$1}', radix: 16)),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Buttons ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: AppStrings.create,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _createCategory,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
