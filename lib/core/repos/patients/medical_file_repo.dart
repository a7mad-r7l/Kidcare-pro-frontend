import 'dart:convert';
import '../../../models/patients/medical_file_model.dart';
import '../../apis/patients/medical_file_api.dart';

class MedicalFileRepo {
  final MedicalFileApi api;
  MedicalFileRepo({required this.api});

  Future<MedicalSummary> getFile(int id) async {
    final res = await api.getMedicalFile(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    if (decoded['status'] == 'success' && decoded['summary'] != null) {
      return MedicalSummary.fromJson(decoded['summary']);
    } else {
      // إرجاع رسالة الخطأ القادمة من السيرفر إن وجدت
      throw Exception(decoded['message'] ?? 'Server error occurred');
    }
  }
}