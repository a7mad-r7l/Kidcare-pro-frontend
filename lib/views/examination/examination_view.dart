import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../../core/constants.dart';
import '../../widgets/custom_button.dart';

class ExaminationView extends GetView<ExaminationController> {
  const ExaminationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.theme.cardColor,
        foregroundColor: context.theme.textTheme.bodyLarge?.color,
        elevation: 0,
        surfaceTintColor: context.theme.cardColor,
        title: Text('Patient Examination'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPatientHeader(context),
            _buildTabs(context),
            Expanded(
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 1:
                    return _buildPrescriptionTab(context);
                  case 0:
                  default:
                    return _buildDiagnosisTab(context);
                }
              }),
            ),
            _buildBottomAction(context),
          ],
        ),
      ),
    );
  }

  // ─── ترويسة المريض (الصورة / الاسم / العمر / المعرف / المؤقت) ───
  Widget _buildPatientHeader(BuildContext context) {
    return Obx(() {
      final patient = controller.patient.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.theme.primaryColor.withOpacity(0.12),
              backgroundImage: patient != null && patient.image.isNotEmpty
                  // الباك إند قد يرجع رابطاً كاملاً أو مساراً نسبياً
                  ? NetworkImage(
                      patient.image.startsWith('http')
                          ? patient.image
                          : '$baseUrl/${patient.image}',
                    )
                  : null,
              child: patient == null || patient.image.isEmpty
                  ? Icon(
                      Icons.person,
                      color: context.theme.primaryColor,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.name ?? 'Loading...',
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient != null
                        ? '${patient.age} Yrs • ${patient.gender.tr}'
                        : '',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.formattedPatientId,
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.theme.hintColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  controller.formattedTime,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ─── شريط التبويبات (التشخيص / الوصفة) ───
  Widget _buildTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Obx(
        () => Row(
          children: [
            _buildTabItem(context, 1, 'Prescription'.tr),
            _buildTabItem(context, 0, 'Diagnosis'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String label) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : context.theme.hintColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── تبويب التشخيص (التشخيص السريري / الملاحظات / بطاقة القياسات) ───
  Widget _buildDiagnosisTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitledCard(
            context,
            icon: Icons.edit_note,
            title: 'Clinical Diagnosis'.tr,
            child: _buildMultilineField(
              context,
              controller: controller.diagnosisController,
              hintText: 'Write the clinical diagnosis for the case'.tr,
              maxLines: 5,
              maxLength: 500,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTitledCard(
            context,
            icon: Icons.description_outlined,
            title: 'General Doctor Notes'.tr,
            child: _buildMultilineField(
              context,
              controller: controller.doctorNotesController,
              hintText:
                  "Write any general notes about the child's condition".tr,
              maxLines: 4,
              maxLength: 300,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildMeasurementsCard(context),
        ],
      ),
    );
  }

  // بطاقة القياسات القابلة للطي (اختيارية) — الطول والوزن معاً
  Widget _buildMeasurementsCard(BuildContext context) {
    return Obx(() {
      final expanded = controller.measurementsExpanded.value;
      return Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Column(
          children: [
            // رأس البطاقة القابل للنقر لفتح/طي الحقول
            InkWell(
              onTap: () => controller.measurementsExpanded.toggle(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 20,
                      color: context.theme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${'Measurements'.tr} (${'Optional'.tr})',
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: context.theme.hintColor,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLabeledField(
                        context,
                        controller: controller.heightController,
                        label: 'Height'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLabeledField(
                        context,
                        controller: controller.weightController,
                        label: 'Weight'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ─── تبويب الوصفة (بطاقة الأدوية + بطاقة التحاليل والأشعة) ───
  Widget _buildPrescriptionTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedicationsCard(context),
          const SizedBox(height: 16),
          _buildLabSection(context),
        ],
      ),
    );
  }

  // بطاقة وصفة الأدوية — العنوان مع رابط "إضافة دواء" وزر "إضافة دواء آخر" بالأسفل داخلها
  Widget _buildMedicationsCard(BuildContext context) {
    return _buildTitledCard(
      context,
      icon: Icons.medication_outlined,
      title: 'Medications Prescription'.tr,
      trailing: _buildAddLink(
        context,
        'Add Medication'.tr,
        () => controller.addMedicationField(),
      ),
      child: Obx(
        () => Column(
          children: [
            for (int i = 0; i < controller.medications.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: context.theme.dividerColor),
                const SizedBox(height: 8),
              ],
              _buildMedicationEntry(context, i),
            ],
            const SizedBox(height: 12),
            _buildAddAnotherButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationEntry(BuildContext context, int index) {
    final med = controller.medications[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر الحذف (X) يظهر فقط عند وجود أكثر من دواء
        if (controller.medications.length > 1)
          Align(
            alignment: AlignmentDirectional.topStart,
            child: GestureDetector(
              onTap: () => controller.removeMedicationField(index),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ),
        _buildLabeledField(
          context,
          controller: med.nameController,
          label: 'Medicine Name'.tr,
        ),
        const SizedBox(height: 12),
        // الجرعة والتعليمات كلٌّ في حقل مستقل
        _buildLabeledField(
          context,
          controller: med.dosageController,
          label: 'Dosage'.tr,
        ),
        const SizedBox(height: 12),
        _buildLabeledField(
          context,
          controller: med.timingController,
          label: 'Instructions'.tr,
        ),
        const SizedBox(height: 12),
        // الكمية والمدة جنباً إلى جنب
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                context,
                controller: med.frequencyController,
                label: 'Quantity'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                context,
                controller: med.durationController,
                label: 'Duration'.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // زر "إضافة دواء آخر" الممتد أسفل بطاقة الأدوية
  Widget _buildAddAnotherButton(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.addMedicationField(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: context.theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Add Another Medication'.tr,
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

  // بطاقة طلب التحاليل وصور الأشعة — يضيف الطبيب طلبات عبر زر ثم تظهر كصفوف
  Widget _buildLabSection(BuildContext context) {
    return _buildTitledCard(
      context,
      icon: Icons.science_outlined,
      title: 'Lab & Imaging Requests'.tr,
      trailing: _buildAddLink(
        context,
        'Add Request'.tr,
        () => _showAddLabRequestSheet(context),
      ),
      child: Obx(() {
        if (controller.labRequests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No requests added'.tr,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < controller.labRequests.length; i++)
              _buildLabRequestRow(context, i),
          ],
        );
      }),
    );
  }

  // صف طلب واحد: أيقونة النوع + القيمة + زر الحذف
  Widget _buildLabRequestRow(BuildContext context, int index) {
    final item = controller.labRequests[index];
    final isTest = item.type == LabRequestType.test;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            isTest ? Icons.biotech_outlined : Icons.image_outlined,
            size: 20,
            color: context.theme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.value,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: context.theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.removeLabRequest(index),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  // اختيار النوع (تحليل/أشعة) ثم إدخال القيمة عبر نافذة حوارية
  void _showAddLabRequestSheet(BuildContext context) {
    Get.dialog(
      _AddLabRequestDialog(
        onAdd: (type, value) => controller.addLabRequest(type, value),
      ),
    );
  }

  // ─── زر الإجراء السفلي يتغير حسب التبويب الحالي ───
  Widget _buildBottomAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Obx(() {
        final isPrescription = controller.selectedTab.value == 1;
        if (isPrescription) {
          // زر أخضر مدمج (إنهاء المعاينة) — لتفادي تعديل الزر المشترك CustomButton
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: controller.isLoading
                  ? null
                  : () => controller.saveAndFinish(),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Save & Finish Examination'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }
        return CustomButton(
          text: 'Save & Continue'.tr,
          isLoading: controller.isLoading,
          onPressed: () => controller.saveAndContinue(),
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  // بطاقة بعنوان وأيقونة (مع إجراء اختياري بجانب العنوان) تحتوي على محتواها
  Widget _buildTitledCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: context.theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(child: _buildSectionTitle(context, title)),
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
  Widget _buildAddLink(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 16, color: context.theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: context.theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // حقل بعنوان صغير فوقه — مصمم ليطابق CustomTextField دون تعديله (بلا أيقونة)
  Widget _buildLabeledField(
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
            fillColor: context.theme.cardColor,
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
        ),
      ],
    );
  }

  // حقل نصي متعدد الأسطر مع عدّاد — مصمم ليطابق CustomTextField دون تعديله
  Widget _buildMultilineField(
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
        hintStyle: TextStyle(color: context.theme.hintColor.withOpacity(0.6)),
        filled: true,
        fillColor: fillColor ?? context.theme.cardColor,
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
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _AddLabRequestDialog extends StatefulWidget {
  final void Function(LabRequestType, String) onAdd;

  const _AddLabRequestDialog({required this.onAdd});

  @override
  State<_AddLabRequestDialog> createState() => _AddLabRequestDialogState();
}

class _AddLabRequestDialogState extends State<_AddLabRequestDialog> {
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
