import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/schedule/schedule_controller.dart';
import '../../core/constants.dart';

class ScheduleView extends GetView<ScheduleController> {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Appointments Schedule'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: context.theme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط "الكل" والعدد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                Text(
                  'All'.tr,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => CircleAvatar(
                  radius: 12,
                  backgroundColor: context.theme.primaryColor,
                  child: Text(
                    controller.scheduleData.value?.totalAppointments.toString() ?? '0',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),

          // الشريط الأفقي للتواريخ (تم دمج التحقق من الأيام هنا)
          SizedBox(
            height: 90,
            child: Obx(() {
              if (controller.isLoading && controller.weekDates.isEmpty) {
                return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
              }

              if (controller.weekDates.isEmpty) {
                return Center(
                  child: Text(
                    'No working days available'.tr,
                    style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.weekDates.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final date = controller.weekDates[index];
                  final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(controller.selectedDate.value);

                  return GestureDetector(
                    onTap: () => controller.onDateSelected(date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.getDayName(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? context.theme.primaryColor : context.theme.hintColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? context.theme.primaryColor : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : context.theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day} ${controller.getMonthName(date)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? context.theme.primaryColor : context.theme.hintColor,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 10),

          // قائمة المواعيد
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.weekDates.isNotEmpty) {
                return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
              }

              final appointments = controller.scheduleData.value?.appointments ?? [];

              if (appointments.isEmpty) {
                return Center(child: Text('No appointments for this date'.tr));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  // تحديد البطاقة الأولى للتمييز بناءً على التصميم
                  final isFirst = index == 0;

                  // ─── تم التعديل هنا: إضافة Padding و InkWell للانتقال ───
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // الانتقال لشاشة التفاصيل وتمرير معرّف الموعد
                        Get.toNamed('/appointment_details', arguments: appointment.id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isFirst ? context.theme.primaryColor.withValues(alpha: 0.08) : context.theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFirst ? context.theme.primaryColor.withValues(alpha: 0.3) : context.theme.dividerColor.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.theme.shadowColor.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // بيانات الوقت في اليسار
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${appointment.time} ${appointment.timePeriod.tr}',
                                  style: context.theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${appointment.duration} ${'minutes'.tr}',
                                  style: context.theme.textTheme.bodySmall?.copyWith(
                                    color: context.theme.hintColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // بيانات المريض في المنتصف
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    appointment.patientName,
                                    style: context.theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${appointment.age} ${appointment.ageType.tr} - ${appointment.gender.tr}',
                                    style: context.theme.textTheme.bodySmall?.copyWith(
                                      color: context.theme.hintColor,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    appointment.note,
                                    style: context.theme.textTheme.bodySmall?.copyWith(
                                      color: context.theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // الصورة والنقطة في اليمين
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
                                  backgroundImage: appointment.image.isNotEmpty
                                      ? NetworkImage('$baseUrl/${appointment.image}')
                                      : null,
                                  child: appointment.image.isEmpty
                                      ? Icon(Icons.person, color: context.theme.hintColor)
                                      : null,
                                ),
                                Positioned(
                                  right: -4,
                                  top: 15,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: context.theme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.theme.cardColor, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}