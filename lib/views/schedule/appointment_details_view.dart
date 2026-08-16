import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/schedule/appointment_details_controller.dart';
import '../../core/constants.dart';

// تم استدعاء المودل هنا لتعريف نوع البيانات
import '../../models/home/doctor_dashboard_model.dart';
import '../../models/schedule/appointment_details_model.dart';

class AppointmentDetailsView extends GetView<AppointmentDetailsController> {
  const AppointmentDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: context.theme.textTheme.bodyLarge?.color,
        ),
        title: Text(
          'Appointment Details'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final data = controller.appointmentDetails.value;
        if (data == null) {
          return Center(child: Text('No details found'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(context, data),
              const SizedBox(height: 24),
              Text(
                'Appointment Info'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildAppointmentInfoCard(context, data),
              const SizedBox(height: 24),
              Text(
                'Parents Notes'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotesCard(context, data),
              const SizedBox(height: 32),
              if (data.status != 'cancelled_by_clinic' &&
                  data.status != 'cancelled_by_patient' &&
                  data.status != 'completed')
                _buildActionButtons(context, data),
            ],
          ),
        );
      }),
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildPatientHeader(
    BuildContext context,
    AppointmentDetailsModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
            backgroundImage: data.childImage.isNotEmpty
                ? NetworkImage('$baseUrl/${data.childImage}')
                : null,
            child: data.childImage.isEmpty
                ? Icon(Icons.person, size: 35, color: context.theme.hintColor)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.childName,
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: context.theme.hintColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.childAge} ${'Yrs'.tr} - ${data.childGender.tr}',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'File No'.tr}: ${data.fileNumber}',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildAppointmentInfoCard(
    BuildContext context,
    AppointmentDetailsModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Date'.tr,
            '${data.day.tr}, ${data.date}',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.access_time, 'Time'.tr, data.time.tr),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.person_outline,
            'Appointment Type'.tr,
            data.appointmentType.tr,
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(
            context,
            Icons.credit_card,
            'Payment Status'.tr,
            data.paymentStatus,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.attach_money,
            'Consultation Fee'.tr,
            '${data.consultationFee} ${data.currency}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: context.theme.hintColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: context.theme.hintColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    BuildContext context,
    IconData icon,
    String label,
    String status,
  ) {
    Color badgeColor = status == 'partially_paid' || status == 'paid'
        ? Colors.green
        : Colors.orange;

    return Row(
      children: [
        Icon(icon, color: context.theme.hintColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: context.theme.hintColor,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.tr,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildNotesCard(BuildContext context, AppointmentDetailsModel data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        data.parentsNotes,
        style: context.theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  // 👈 تم إضافة استقبال متغير data
  Widget _buildActionButtons(
    BuildContext context,
    AppointmentDetailsModel data,
  ) {
    return Row(
      children: [
        // زر الإلغاء (فارغ حالياً ريثما نربطه لاحقاً بـ API الإلغاء)
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => controller.confirmCancellation(),
            child: Text(
              'Cancel Appointment'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // زر بدء المعاينة (التعديل الجذري تم هنا)
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // 1. استخراج بيانات المريض والموعد من الواجهة الحالية وتجهيزها
              final patientToExamine = PatientModel(
                id: data.childId,
                appointmentId: data.appointmentId,
                name: data.childName,
                age: data.childAge,
                gender: data.childGender,
                image: data.childImage,
                appointmentTime: data.time,
              );

              // 2. الانتقال إلى شاشة المعاينة وتمرير البيانات معها
              Get.toNamed('/examination', arguments: patientToExamine);
            },
            child: Text(
              'Start Consultation'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
