import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/examination/examination_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../base_controller.dart';
import '../home/home_controller.dart';

// حامل بسيط لحقول دواء واحد في الواجهة (إضافة دواء آخر تضيف نسخة جديدة)
class MedicationFormData {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController(); // الكمية
  final timingController = TextEditingController(); // التعليمات
  final durationController = TextEditingController();

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      dosageController.text.trim().isEmpty &&
      frequencyController.text.trim().isEmpty &&
      timingController.text.trim().isEmpty &&
      durationController.text.trim().isEmpty;

  bool get isComplete =>
      nameController.text.trim().isNotEmpty &&
      dosageController.text.trim().isNotEmpty &&
      frequencyController.text.trim().isNotEmpty &&
      timingController.text.trim().isNotEmpty &&
      durationController.text.trim().isNotEmpty;

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    timingController.dispose();
    durationController.dispose();
  }
}

// نوع طلب التحاليل/الأشعة: تحليل أو صورة أشعة
enum LabRequestType { test, imaging }

// عنصر واحد في قائمة طلبات التحاليل/الأشعة (النوع + القيمة النصية)
class LabRequestItem {
  final LabRequestType type;
  final String value;

  LabRequestItem({required this.type, required this.value});
}

class ExaminationController extends BaseController {
  final ExaminationRepo repo;

  ExaminationController({required this.repo});

  // 0 = التشخيص ، 1 = الوصفة
  final selectedTab = 0.obs;

  // بطاقة القياسات القابلة للطي داخل تبويب التشخيص (اختيارية)
  final measurementsExpanded = false.obs;

  final patient = Rxn<PatientModel>();

  // recordId يُضبط بعد حفظ التشخيص، وهو مطلوب لإضافة الأدوية
  int? recordId;

  // حقول التشخيص
  final diagnosisController = TextEditingController();
  final doctorNotesController = TextEditingController();

  // حقول القياسات
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  // الأدوية (تبدأ بنموذج فارغ واحد)
  final medications = <MedicationFormData>[MedicationFormData()].obs;

  // طلب تحاليل وصور أشعة — قائمة عناصر يختار الطبيب نوعها ويُدخل قيمتها
  // تُجمَّع قيم التحاليل في required_tests وقيم الأشعة في required_imaging
  final labRequests = <LabRequestItem>[].obs;

  // المؤقت التنازلي للمعاينة (للعرض فقط)
  final remainingSeconds = (15 * 60 + 30).obs;
  Timer? _timer;

  String get formattedTime {
    final total = remainingSeconds.value;
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedPatientId {
    final id = patient.value?.id ?? 0;
    return 'PT-${DateTime.now().year}-${id.toString().padLeft(4, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PatientModel) {
      patient.value = args;
    } else {
      fetchNextPatient();
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> fetchNextPatient() async {
    showLoading();
    try {
      patient.value = await repo.getNextPatient();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── الشاشة الأولى: حفظ وتقدم (التشخيص + القياسات) ───
  Future<void> saveAndContinue() async {
    final diagnosis = diagnosisController.text.trim();
    if (diagnosis.isEmpty) {
      selectedTab.value = 0; // البقاء في تبويب التشخيص لإظهار الحقل المطلوب
      showInfo('Please enter the diagnosis'.tr);
      return;
    }

    final heightText = heightController.text.trim();
    final weightText = weightController.text.trim();
    final hasHeight = heightText.isNotEmpty;
    final hasWeight = weightText.isNotEmpty;
    if (hasHeight != hasWeight) {
      selectedTab.value = 0; // القياسات أصبحت داخل تبويب التشخيص
      measurementsExpanded.value = true; // فتح البطاقة لإظهار الحقول
      showInfo('Please enter both height and weight'.tr);
      return;
    }

    final appointmentId = patient.value?.appointmentId ?? 0;

    showLoading();
    try {
      final record = await repo.saveDiagnosis(
        appointmentId,
        diagnosis: diagnosis,
        doctorNotes: doctorNotesController.text.trim().isEmpty
            ? null
            : doctorNotesController.text.trim(),
      );
      recordId = record.id;

      if (hasHeight && hasWeight) {
        await repo.saveGrowth(
          appointmentId,
          height: num.tryParse(heightText) ?? 0,
          weight: num.tryParse(weightText) ?? 0,
        );
      }

      hideLoading();
      showSuccess('Diagnosis saved successfully'.tr);
      selectedTab.value = 1; // الانتقال لتبويب الوصفة
    } catch (e) {
      handleError(e);
    }
  }

  void addMedicationField() {
    medications.add(MedicationFormData());
  }

  void removeMedicationField(int index) {
    if (index < 0 || index >= medications.length) return;
    medications[index].dispose();
    medications.removeAt(index);
  }

  // إضافة طلب تحليل/أشعة بعد اختيار النوع وإدخال القيمة
  void addLabRequest(LabRequestType type, String value) {
    if (value.trim().isEmpty) return;
    labRequests.add(LabRequestItem(type: type, value: value.trim()));
  }

  void removeLabRequest(int index) {
    if (index < 0 || index >= labRequests.length) return;
    labRequests.removeAt(index);
  }

  // ─── الشاشة الثانية: حفظ وإنهاء المعاينة ───
  Future<void> saveAndFinish() async {
    if (recordId == null) {
      selectedTab.value = 0; // العودة لتبويب التشخيص لحفظه أولاً
      showInfo('Please save the diagnosis first'.tr);
      return;
    }

    // أي نموذج مملوء جزئياً يعتبر خطأ؛ النماذج الفارغة تماماً تُتجاهل
    final hasPartial = medications.any((m) => !m.isEmpty && !m.isComplete);
    if (hasPartial) {
      showInfo('Please complete all medication fields'.tr);
      return;
    }

    final completeMeds = medications.where((m) => m.isComplete).toList();

    showLoading();
    try {
      for (final med in completeMeds) {
        await repo.addMedication(
          recordId!,
          name: med.nameController.text.trim(),
          dosage: med.dosageController.text.trim(),
          frequency: med.frequencyController.text.trim(),
          timing: med.timingController.text.trim(),
          duration: med.durationController.text.trim(),
        );
      }

      // طلب التحاليل/الأشعة — تُجمَّع قيم كل نوع بفاصلة وتُرسل فقط إن وُجدت
      final tests = labRequests
          .where((r) => r.type == LabRequestType.test)
          .map((r) => r.value)
          .join(', ');
      final imaging = labRequests
          .where((r) => r.type == LabRequestType.imaging)
          .map((r) => r.value)
          .join(', ');
      if (tests.isNotEmpty || imaging.isNotEmpty) {
        await repo.saveMedicalRequests(
          patient.value?.appointmentId ?? 0,
          requiredTests: tests.isEmpty ? null : tests,
          requiredImaging: imaging.isEmpty ? null : imaging,
        );
      }

      final msg = await repo.completeAppointment(
        patient.value?.appointmentId ?? 0,
      );

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchAllDashboardData();
      }

      hideLoading();
      showSuccess(msg);
      Get.offAllNamed('/doctor_home');
    } catch (e) {
      handleError(e);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    diagnosisController.dispose();
    doctorNotesController.dispose();
    heightController.dispose();
    weightController.dispose();
    for (final med in medications) {
      med.dispose();
    }
    super.onClose();
  }
}
