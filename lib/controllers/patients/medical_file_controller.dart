import 'package:get/get.dart';
import '../../core/repos/patients/medical_file_repo.dart';
import '../../core/repos/patients/prescription_record_repo.dart';
import '../../models/patients/medical_file_model.dart';
import '../../models/patients/prescription_record_model.dart';
import '../base_controller.dart';

class MedicalFileController extends BaseController {
  final MedicalFileRepo repo;
  MedicalFileController({required this.repo});

  // مستودع الوصفات والملاحظات
  final PrescriptionRecordRepo detailsRepo = PrescriptionRecordRepo();

  // قوائم لتخزين البيانات المحملة (لمنع إعادة التحميل مرتين)
  final RxMap<int, PrescriptionModel> prescriptions = <int, PrescriptionModel>{}.obs;
  final RxMap<int, MedicalRecordModel> medicalRecords = <int, MedicalRecordModel>{}.obs;
  final RxSet<int> loadingDetails = <int>{}.obs;

  final summary = Rxn<MedicalSummary>();
  late final int patientId;
  String patientName = '';
  String patientAge = '';
  String patientGender = '';
  String patientFileNumber = '';
  String patientImage = '';

  final selectedTab = 0.obs;

  final List<String> tabs = [
    'Summary',
    'Growth Chart',
    'Visits & Prescriptions' // 👈 التبويب الثالث
  ];

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg != null) {
      _extractPatientData(arg);
      if (patientId != 0) fetchMedicalFile();
    }
  }

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

  // 👈 دالة جلب الوصفة والملاحظات معاً
  Future<void> fetchVisitDetails(int recordId, int appointmentId) async {
    print('--- Fetching Visit Details ---');
    print('Record ID (Prescription): $recordId');
    print('Appointment ID (Notes): $appointmentId');

    // إذا لم يرسل الباك إند أي معرفات، توقف
    if (recordId == 0 && appointmentId == 0) {
      print('⚠️ كلا المعرفين 0. يرجى التأكد من أن الباك إند يرسلهما في الـ Summary.');
      return;
    }

    // اعتماد مفتاح تحميل موحد لتفادي تكرار الطلب
    final int loadingKey = appointmentId != 0 ? appointmentId : recordId;

    if (loadingDetails.contains(loadingKey)) return;
    loadingDetails.add(loadingKey);

    try {
      // جلب الوصفة (إذا كان لها معرف)
      if (recordId != 0 && !prescriptions.containsKey(recordId)) {
        prescriptions[recordId] = await detailsRepo.fetchPrescription(recordId);
      }

      // جلب الملاحظات (إذا كان لها معرف)
      if (appointmentId != 0 && !medicalRecords.containsKey(appointmentId)) {
        medicalRecords[appointmentId] = await detailsRepo.fetchMedicalRecord(appointmentId);
      }
    } catch (e) {
      print('❌ Error fetching details: $e');
    } finally {
      loadingDetails.remove(loadingKey);
    }
  }

  void changeTab(int index) => selectedTab.value = index;
}