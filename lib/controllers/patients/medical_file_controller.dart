import 'package:get/get.dart';
import '../../core/repos/patients/medical_file_repo.dart';
import '../../models/patients/medical_file_model.dart';
import '../base_controller.dart';

class MedicalFileController extends BaseController {
  final MedicalFileRepo repo;
  MedicalFileController({required this.repo});

  final summary = Rxn<MedicalSummary>();

  // 👈 متغيرات لحفظ بيانات المريض الممررة من الواجهة السابقة
  late final int patientId;
  String patientName = '';
  String patientAge = '';
  String patientGender = '';
  String patientFileNumber = '';
  String patientImage = '';

  final selectedTab = 0.obs;

  // 👈 تم تقليص التبويبات إلى 2 فقط
  final List<String> tabs = [
    'Summary'.tr,
    'Growth Chart'.tr,
  ];

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;

    if (arg != null) {
      _extractPatientData(arg);
      if (patientId != 0) {
        fetchMedicalFile();
      }
    }
  }

  // 👈 استخراج بيانات المريض بمرونة من الكائن الممرر
  void _extractPatientData(dynamic arg) {
    try { patientId = arg.id ?? 0; } catch (_) { patientId = 0; }
    try { patientName = arg.name ?? ''; } catch (_) {}
    try { patientImage = arg.image ?? ''; } catch (_) {}
    try { patientGender = arg.gender ?? ''; } catch (_) {}

    try {
      final age = arg.age?.toString() ?? '';
      final ageType = arg.ageType?.toString() ?? 'year';
      patientAge = '$age ${ageType.tr}';
    } catch (_) {}

    try {
      patientFileNumber = arg.fileNumber ?? 'PT-2024-$patientId';
    } catch (_) {
      patientFileNumber = 'PT-2024-$patientId';
    }
  }

  Future<void> fetchMedicalFile() async {
    showLoading();
    try {
      final data = await repo.getFile(patientId);
      summary.value = data;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }
}