import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings/doctor_availability_controller.dart';
import '../../models/settings/available_period_model.dart';

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
      floatingActionButton: Obx(
        () => controller.selectedTab.value == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showAddBottomSheet(context),
                backgroundColor: context.theme.primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Enter Working Day'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          // ─── Tabs Switcher ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Obx(
                () => Row(
                  children: [
                    _buildTab(
                      context,
                      0,
                      'My Availabilities'.tr,
                      Icons.calendar_month,
                    ),
                    _buildTab(
                      context,
                      1,
                      'Free Slots'.tr,
                      Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ─── Content ───
          Expanded(
            child: Obx(() {
              if (controller.isFetching.value &&
                  controller.availabilitiesList.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.theme.primaryColor,
                  ),
                );
              }

              return RefreshIndicator(
                color: context.theme.primaryColor,
                onRefresh: controller.fetchAllData,
                child: controller.selectedTab.value == 0
                    ? _buildMyAvailabilitiesList(context)
                    : _buildFreePeriodsList(context),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Tab Widget ───
  Widget _buildTab(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : context.theme.hintColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected
                      ? Colors.white
                      : context.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 0: My Availabilities ───
  Widget _buildMyAvailabilitiesList(BuildContext context) {
    if (controller.availabilitiesList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              'There are no available days'.tr,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
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
              item.dayOfWeek.tr,
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
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, item.id),
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 1: Free Slots ───
  Widget _buildFreePeriodsList(BuildContext context) {
    if (controller.availablePeriodsList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              'No free slots available'.tr,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      itemCount: controller.availablePeriodsList.length,
      itemBuilder: (context, index) {
        final dayData = controller.availablePeriodsList[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                dayData.dayName.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (dayData.freePeriods.isEmpty)
              Text(
                'No times available for this date.'.tr,
                style: TextStyle(color: context.theme.hintColor, fontSize: 13),
              ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: dayData.freePeriods
                  .map(
                    (period) =>
                        _buildFreeSlotChip(context, dayData.day, period),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Divider(color: context.theme.dividerColor.withOpacity(0.5)),
          ],
        );
      },
    );
  }

  Widget _buildFreeSlotChip(
    BuildContext context,
    String day,
    FreePeriodModel period,
  ) {
    return GestureDetector(
      onTap: () {
        controller.preFillData(day, period.startTime, period.endTime);

        _showAddBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.theme.primaryColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 16,
              color: context.theme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              '${period.startTime} - ${period.endTime}',
              style: TextStyle(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───
  void _confirmDelete(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete this working day?'.tr),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () {
              Get.back();
              controller.deleteDay(id);
            },
            child: Text(
              'Delete'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                      items: controller.apiDays.map((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day.tr),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          controller.selectedDay.value = newValue;
                        }
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
