import 'dart:convert';
import '../../../models/patients/prescription_record_model.dart';
import '../../apis/patients/prescription_record_api.dart';

class PrescriptionRecordRepo {
  final PrescriptionRecordApi api;
  PrescriptionRecordRepo({PrescriptionRecordApi? api}) : api = api ?? PrescriptionRecordApi();

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    return response;
  }

  Future<PrescriptionModel> fetchPrescription(int recordId) async {
    final res = await api.getPrescription(recordId);
    print('💊 Prescription API Status: ${res.statusCode}');
    print('💊 Prescription API Body: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = json.decode(_cleanJson(res.body));
      return PrescriptionModel.fromJson(decoded['prescription'] ?? {});
    } else {
      throw Exception('Failed to fetch prescription (Status: ${res.statusCode})');
    }
  }

  Future<MedicalRecordModel> fetchMedicalRecord(int appointmentId) async {
    final res = await api.getMedicalRecord(appointmentId);
    print('📝 Medical Record API Status: ${res.statusCode}');
    print('📝 Medical Record API Body: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = json.decode(_cleanJson(res.body));
      return MedicalRecordModel.fromJson(decoded['medical_record'] ?? {});
    } else {
      throw Exception('Failed to fetch medical record (Status: ${res.statusCode})');
    }
  }
}