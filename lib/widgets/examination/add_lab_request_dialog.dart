import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';

// اختيار النوع (تحليل/أشعة) ثم إدخال القيمة عبر نافذة حوارية
class AddLabRequestDialog extends StatefulWidget {
  final void Function(LabRequestType, String) onAdd;

  const AddLabRequestDialog({super.key, required this.onAdd});

  @override
  State<AddLabRequestDialog> createState() => _AddLabRequestDialogState();
}

class _AddLabRequestDialogState extends State<AddLabRequestDialog> {
  final _valueController = TextEditingController();
  LabRequestType _selectedType = LabRequestType.test;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Add Request'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip(
                    context,
                    label: 'Test'.tr,
                    icon: Icons.biotech_outlined,
                    selected: _selectedType == LabRequestType.test,
                    onTap: () => setState(() => _selectedType = LabRequestType.test),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypeChip(
                    context,
                    label: 'Imaging'.tr,
                    icon: Icons.image_outlined,
                    selected: _selectedType == LabRequestType.imaging,
                    onTap: () => setState(() => _selectedType = LabRequestType.imaging),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildValueField(context),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final value = _valueController.text.trim();
            if (value.isEmpty) return;
            widget.onAdd(_selectedType, value);
            Get.back();
          },
          child: Text('Add'.tr),
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? context.theme.primaryColor : context.theme.hintColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.theme.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Value'.tr,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.hintColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _valueController,
          autofocus: true,
          style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
