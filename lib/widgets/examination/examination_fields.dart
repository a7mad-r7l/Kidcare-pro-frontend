import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── عناصر واجهة مشتركة داخل شاشة المعاينة (بطاقات وحقول) ───
// مُجمَّعة هنا لتفادي تكرارها عبر بطاقات المعاينة المستخرَجة.

// عنوان قسم صغير
Widget buildSectionTitle(BuildContext context, String title) {
  return Text(
    title,
    style: context.theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
}

// بطاقة بعنوان وأيقونة (مع إجراء اختياري بجانب العنوان) تحتوي على محتواها
Widget buildTitledCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  Widget? trailing,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(child: buildSectionTitle(context, title)),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

// رابط إجراء صغير (+ نص) يُوضع بجانب عنوان البطاقة
Widget buildAddLink(BuildContext context, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// حقل بعنوان صغير فوقه — مصمم ليطابق CustomTextField دون تعديله (بلا أيقونة)
Widget buildLabeledField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.theme.textTheme.bodySmall?.copyWith(
          color: context.theme.hintColor,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );
}

// حقل نصي متعدد الأسطر مع عدّاد — مصمم ليطابق CustomTextField دون تعديله
Widget buildMultilineField(
  BuildContext context, {
  required TextEditingController controller,
  required String hintText,
  required int maxLines,
  required int maxLength,
  Color? fillColor,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLength,
    style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: context.theme.hintColor.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: fillColor ?? Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.5,
        ),
      ),
    ),
  );
}
