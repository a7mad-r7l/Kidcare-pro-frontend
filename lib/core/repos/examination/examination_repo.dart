import 'dart:convert';
import '../../../models/examination/diagnosis_record_model.dart';
import '../../../models/examination/medication_model.dart';
import '../../../models/home/doctor_dashboard_model.dart';
import '../../apis/examination/examination_api.dart';

class ExaminationRepo {
  final ExaminationApi api;
  ExaminationRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    if (response.contains('[')) return response.substring(response.indexOf('['));
    return response;
  }

  Future<PatientModel?> getNextPatient() async {
    final res = await api.getNextPatient();
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded['message'] == 'No upcoming patients') return null;
    return PatientModel.fromJson(decoded);
  }

  Future<DiagnosisRecordModel> saveDiagnosis(
    int appointmentId, {
    required String diagnosis,
    String? doctorNotes,
  }) async {
    final res = await api.saveDiagnosis(
      appointmentId,
      diagnosis: diagnosis,
      doctorNotes: doctorNotes,
    );
    final decoded = jsonDecode(_cleanJson(res));
    return DiagnosisRecordModel.fromJson(decoded['record']);
  }

  Future<String> saveGrowth(
    int appointmentId, {
    required num height,
    required num weight,
  }) async {
    final res = await api.saveGrowth(
      appointmentId,
      height: height,
      weight: weight,
    );
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }

  Future<MedicationModel> addMedication(
    int recordId, {
    required String name,
    required String dosage,
    required String frequency,
    required String timing,
    required String duration,
  }) async {
    final res = await api.addMedication(
      recordId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      timing: timing,
      duration: duration,
    );
    final decoded = jsonDecode(_cleanJson(res));
    return MedicationModel.fromJson(decoded['medication']);
  }

  Future<String> saveMedicalRequests(
    int appointmentId, {
    String? requiredTests,
    String? requiredImaging,
  }) async {
    final res = await api.saveMedicalRequests(
      appointmentId,
      requiredTests: requiredTests,
      requiredImaging: requiredImaging,
    );
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }

  Future<String> completeAppointment(int appointmentId) async {
    final res = await api.completeAppointment(appointmentId);
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }
}
