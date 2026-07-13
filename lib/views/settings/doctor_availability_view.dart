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
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text('Clinic Settings'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBottomSheet(context),
        backgroundColor: context.theme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Enter Working Day'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: Obx(() {
        if (controller.isFetching.value) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        if (controller.availabilitiesList.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد أوقات دوام مضافة حالياً.',
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: 100,
          ),
          itemCount: controller.availabilitiesList.length,
          itemBuilder: (context, index) {
            final item = controller.availabilitiesList[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.theme.dividerColor.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  item.dayOfWeek.tr, // وصول آمن عبر المودل
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: context.theme.hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.startTime} - ${item.endTime}',
                        style: TextStyle(color: context.theme.hintColor),
                      ),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(context, item.id),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this working day?'.tr), // تم ربطها بالترجمة
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              overlayColor: context.theme.primaryColor.withOpacity(0.1),
            ),
            child: Text('Cancel'.tr, style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              controller.deleteDay(id);
            },
            child: Text('Delete'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Working Day'.tr,
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Day'.tr,
                style: TextStyle(color: context.theme.hintColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(
                    () => DropdownButton<String>(
                      value: controller.selectedDay.value,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: context.theme.primaryColor,
                      ),
                      items: controller.apiDays.map((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day.tr),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null)
                          controller.selectedDay.value = newValue;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerField(
                      context,
                      'Start Time'.tr,
                      true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePickerField(context, 'End Time'.tr, false),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.saveWorkingHours(),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Working Hours'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildTimePickerField(
    BuildContext context,
    String label,
    bool isStartTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.theme.hintColor, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickTime(context, isStartTime),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    isStartTime
                        ? controller.formattedStartTime
                        : controller.formattedEndTime,
                    style: context.theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: context.theme.hintColor.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
