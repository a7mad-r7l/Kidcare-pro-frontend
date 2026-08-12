import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';
import '../../models/invoice/invoice_model.dart';

// ─── بطاقة الخدمات الإضافية — حقلا الاسم والتكلفة ثم قائمة الخدمات المضافة ───
// كل خدمة تُحفظ في الخادم لحظة إضافتها، والقائمة تُرسم من رد الخادم مباشرة.
class ExtraServicesCard extends GetView<InvoiceController> {
  const ExtraServicesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(context, 'Service Name'.tr),
          const SizedBox(height: 6),
          _buildServiceNameField(context),
          const SizedBox(height: 14),
          Obx(
            () => _buildFieldLabel(
              context,
              '${'Cost'.tr} (${controller.currencySymbol})',
            ),
          ),
          const SizedBox(height: 6),
          _buildCostField(context),
          Obx(() {
            final items = controller.additions;
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'No extra services added'.tr,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
              );
            }
            return Column(
              children: [
                const SizedBox(height: 6),
                for (final item in items) _buildServiceRow(context, item),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: context.theme.textTheme.bodySmall?.copyWith(
        color: context.theme.hintColor,
        fontSize: 12,
      ),
    );
  }

  // حقل الاسم — أيقونة داخل الحافة اليمنى/اليسرى وزر مسح سريع
  Widget _buildServiceNameField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.theme.primaryColor.withValues(alpha: 0.10),
              // اتجاهية حتى تلتصق الأيقونة بحافة الحقل في العربية والإنجليزية
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: Radius.circular(11),
              ),
            ),
            child: Icon(
              Icons.vaccines_outlined,
              size: 20,
              color: context.theme.primaryColor,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.serviceNameController,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              style: TextStyle(
                color: context.theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: 'e.g. Nebulizer session'.tr,
                hintStyle: TextStyle(
                  color: context.theme.hintColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: controller.clearServiceName,
            icon: Icon(Icons.close, size: 18, color: context.theme.hintColor),
            tooltip: 'Clear'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildCostField(BuildContext context) {
    return TextField(
      controller: controller.costController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // منع الإشارات والحروف — الخادم يتوقع رقماً موجباً
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.theme.scaffoldBackgroundColor,
        hintText: '0.00',
        hintStyle: TextStyle(
          color: context.theme.hintColor.withValues(alpha: 0.6),
        ),
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
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.theme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // صف خدمة محفوظة — الحذف ينادي الخادم ويعيد رسم الفاتورة من الرد
  Widget _buildServiceRow(BuildContext context, AdditionModel item) {
    final isDeleting = controller.deletingAdditionId.value == item.id;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: context.theme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.itemName,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: context.theme.textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            controller.formatMoney(item.price),
            style: context.theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            height: 36,
            child: isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Material(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => controller.deleteItem(item),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
