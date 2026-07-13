import 'package:get/get.dart';
import '../../core/repos/patients/medical_file_repo.dart';
import '../../models/patients/medical_file_model.dart';
import '../base_controller.dart';

class MedicalFileController extends BaseController {
  final MedicalFileRepo repo;
  MedicalFileController({required this.repo});

  final medicalFile = Rxn<MedicalFileModel>();
  late final int patientId;
  final selectedTab = 0.obs;

  final List<String> tabs = [
    'Summary',
    'Visits & Prescriptions',
    'Growth Chart',
    'Vaccines'
  ];

  @override
  void onInit() {
    super.onInit();
    patientId = Get.arguments as int? ?? 0;
    if (patientId != 0) {
      fetchMedicalFile();
    }
  }

  Future<void> fetchMedicalFile() async {
    showLoading();
    try {
      final data = await repo.getFile(patientId);
      medicalFile.value = data;
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