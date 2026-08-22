// File: lib/views/patients/medical_file_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patients/medical_file_controller.dart';
import '../../core/constants.dart';
import '../../models/patients/medical_file_model.dart';
import '../growth/child_growth_tab_view.dart'; // 👈 استدعاء واجهة النمو

class MedicalFileView extends GetView<MedicalFileController> {
  const MedicalFileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.theme.textTheme.bodyLarge?.color),
        title: Text(
          'Medical File'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading && controller.summary.value == null) {
          return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
        }

        final summaryData = controller.summary.value;
        if (summaryData == null) {
          return Center(child: Text('No details found'.tr));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildPatientHeader(context),
            ),
            const SizedBox(height: 16),
            _buildCustomTabBar(context),
            const SizedBox(height: 16),
            Expanded(
              // 👈 أزلنا الـ SingleChildScrollView من هنا لتجنب مشاكل التمرير
              child: _buildTabContent(context, summaryData),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    // ... (نفس الكود السابق للـ PatientHeader بدون تغيير)
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: controller.patientImage.isNotEmpty
                ? NetworkImage(
              controller.patientImage.startsWith('http')
                  ? controller.patientImage
                  : '$baseUrl/${controller.patientImage}',
            )
                : null,
            onBackgroundImageError: controller.patientImage.isNotEmpty
                ? (exception, stackTrace) {
              // 👈 هذا السطر يمنع الانهيار والخطأ الأحمر في الـ Console عند فشل تحميل الصورة
              debugPrint('⚠️ Failed to load patient image: $exception');
            }
                : null,
            child: controller.patientImage.isEmpty
                ? const Icon(Icons.person, size: 35, color: Colors.white)
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
                      controller.patientName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${controller.patientAge} - ${controller.patientGender.tr}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: ${controller.patientFileNumber}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    // ... (نفس الكود السابق للـ TabBar بدون تغيير)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          controller.tabs.length,
              (index) => Obx(() {
            final isSelected = controller.selectedTab.value == index;
            return GestureDetector(
              onTap: () => controller.changeTab(index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? context.theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.tabs[index].tr,
                  style: TextStyle(
                    color: isSelected ? context.theme.primaryColor : context.theme.hintColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, MedicalSummary summary) {
    return Obx(() {
      switch (controller.selectedTab.value) {
        case 0:
          return _buildSummaryTab(context, summary);
        case 1:
        // 👈 ربط واجهة مخطط النمو وتمرير المعرف
          return ChildGrowthTabView(childId: controller.patientId);
        case 2:
          return _buildVisitsTab(context, summary);
        default:
          return const SizedBox.shrink();
      }
    });
  }
  Widget _buildVisitsTab(BuildContext context, MedicalSummary summary) {
    final allVisits = <VisitModel>[];
    if (summary.lastVisit != null) allVisits.add(summary.lastVisit!);
    allVisits.addAll(summary.previousVisits);

    if (allVisits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text('No visits found'.tr, style: TextStyle(color: context.theme.hintColor)),
        ),
      );
    }

    return ListView.separated(

      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      itemCount: allVisits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildExpandableVisitCard(context, allVisits[index]);
      },
    );
  }

  Widget _buildExpandableVisitCard(BuildContext context, VisitModel visit) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {

            if (expanded) controller.fetchVisitDetails(visit.recordId, visit.appointmentId);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medical_information_outlined, color: context.theme.primaryColor),
          ),
          title: Text(
            visit.date,
            style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            '${'Diagnosis'.tr}: ${visit.diagnosis.tr}',
            style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor),
          ),
          children: [
            Obx(() {
              final loadingKey = visit.appointmentId != 0 ? visit.appointmentId : visit.recordId;
              if (controller.loadingDetails.contains(loadingKey)) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: context.theme.primaryColor),
                );
              }

              final record = controller.medicalRecords[visit.appointmentId];
              final prescription = controller.prescriptions[visit.recordId];

              if (record == null && prescription == null) {

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No details found'.tr, style: TextStyle(color: context.theme.hintColor)),
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: context.theme.dividerColor.withValues(alpha: 0.1)),
                    const SizedBox(height: 8),

                    if (record != null && record.doctorNotes.isNotEmpty && record.doctorNotes != 'null') ...[
                      Row(
                        children: [
                          Icon(Icons.notes, size: 18, color: context.theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Doctor Notes'.tr,
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.theme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.doctorNotes,
                          style: context.theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],


                    if (prescription != null && prescription.medications.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.medication_outlined, size: 18, color: context.theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Medications Prescription'.tr,
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.theme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...prescription.medications.map((med) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.vaccines_outlined, color: context.theme.hintColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: context.theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${med.dosage} • ${med.frequency} • ${med.timing.tr}',
                                    style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${'Duration'.tr}: ${med.duration}',
                                    style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, MedicalSummary summary) {

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildVitalCard(context, 'Weight'.tr, '${summary.weight} ${'kg'.tr}', summary.weightStatus)),
              const SizedBox(width: 12),
              Expanded(child: _buildVitalCard(context, 'Height'.tr, '${summary.height} ${'cm'.tr}', summary.heightStatus)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVitalCard(context, 'Blood Type'.tr, summary.bloodType, null)),
              const SizedBox(width: 12),
              Expanded(child: _buildVitalCard(context, 'Allergies'.tr, summary.allergies.tr, null)),
            ],
          ),
          const SizedBox(height: 24),

          if (summary.lastVisit != null) ...[
            Text('Last Visit'.tr, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: context.theme.primaryColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.lastVisit!.date, style: context.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${'Diagnosis'.tr}: ${summary.lastVisit!.diagnosis.tr}', style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                      ],
                    ),
                  ),
                  Text(summary.lastVisit!.doctorName, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text('Previous Visits'.tr, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                ...summary.previousVisits.map((visit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(visit.date, style: context.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(visit.diagnosis.tr, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                        ],
                      ),
                      Text(visit.doctorName, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildVitalCard(BuildContext context, String title, String value, String? status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
          const SizedBox(height: 8),
          Text(value, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (status != null && status.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.tr,
                style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }
}