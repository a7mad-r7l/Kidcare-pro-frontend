import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/schedule/patients_controller.dart';
import '../../core/constants.dart';
// ─── استدعاء المودل لتعريف نوع البيانات ───
import '../../models/schedule/patient_list_model.dart';

class PatientsView extends GetView<PatientsController> {
  const PatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Patients'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        // تم إزالة زر الإشعارات من هنا
      ),
      body: Column(
        children: [
          // ─── شريط البحث ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for patient name or file number'.tr,
                hintStyle: TextStyle(color: context.theme.hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: context.theme.hintColor),
                // تم إزالة suffixIcon (زر الفلتر) من هنا
                filled: true,
                fillColor: context.theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.dividerColor.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.dividerColor.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.primaryColor),
                ),
              ),
            ),
          ),

          // ─── قائمة المرضى ───
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.patientsList.isEmpty) {
                return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
              }
              if (controller.patientsList.isEmpty) {
                return Center(child: Text('No patients found'.tr));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                itemCount: controller.patientsList.length,
                itemBuilder: (context, index) {
                  final patient = controller.patientsList[index];
                  return _buildPatientCard(context, patient);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── تم تغيير dynamic إلى PatientListModel هنا ───
  Widget _buildPatientCard(BuildContext context, PatientListModel patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
                  backgroundImage: patient.image.isNotEmpty ? NetworkImage('$baseUrl/${patient.image}') : null,
                  child: patient.image.isEmpty ? Icon(Icons.person, color: context.theme.hintColor) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.age} ${patient.ageType.tr} - ${patient.gender.tr}',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'File No'.tr}: ${patient.fileNumber}',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'Phone'.tr}: ${patient.parentPhone}',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.theme.primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Get.toNamed('/medical_file', arguments: patient);
            },
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Center(
                child: Text(
                  'View Medical File'.tr,
                  style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}