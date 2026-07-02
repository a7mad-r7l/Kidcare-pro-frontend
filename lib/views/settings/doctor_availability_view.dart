import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings/doctor_availability_controller.dart';




class DoctorAvailabilityView extends GetView<DoctorAvailabilityController> {
  const DoctorAvailabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.theme.appBarTheme.iconTheme?.color),
          onPressed: () => Get.back(),
        ),
        title: Text('Clinic Settings'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ─── بطاقة إدخال يوم العمل الرئيسية ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_calendar_outlined, color: context.theme.primaryColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Enter Working Day'.tr,
                        style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // حقل اختيار اليوم (Dropdown)
                  Text('Day'.tr, style: TextStyle(color: context.theme.hintColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.theme.scaffoldBackgroundColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(() => DropdownButton<String>(
                        value: controller.selectedDay.value,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: context.theme.primaryColor),
                        items: controller.apiDays.map((String day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(day.tr), // الترجمة ديناميكية لكل يوم
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) controller.selectedDay.value = newValue;
                        },
                      )),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // حقول اختيار الوقت (جنباً إلى جنب)
                  Row(
                    children: [
                      Expanded(child: _buildTimePickerField(context, 'Start Time'.tr, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTimePickerField(context, 'End Time'.tr, false)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── مربع التنبيه الاحترافي الأزرق ───
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.theme.primaryColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: context.theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This day will be saved as your available working hours.'.tr,
                      style: TextStyle(color: context.theme.primaryColor, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            //   حفظ وقت الدوام
            Obx(() => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                onPressed: controller.isLoading ? null : () => controller.saveWorkingHours(),
                child: controller.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Text('Save Working Hours'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerField(BuildContext context, String label, bool isStartTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.theme.hintColor, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickTime(context, isStartTime),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                  isStartTime ? controller.formattedStartTime : controller.formattedEndTime,
                  style: context.theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                )),
                Icon(Icons.access_time, color: context.theme.hintColor.withOpacity(0.6), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}