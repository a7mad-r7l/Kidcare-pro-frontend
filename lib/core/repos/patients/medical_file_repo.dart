import 'dart:convert';
import '../../../models/patients/medical_file_model.dart';
import '../../apis/patients/medical_file_api.dart';

class MedicalFileRepo {
  final MedicalFileApi api;
  MedicalFileRepo({required this.api});

  Future<MedicalFileModel> getFile(int id) async {
    final res = await api.getMedicalFile(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);
    if (decoded['status'] == true && decoded['data'] != null) {
      return MedicalFileModel.fromJson(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to fetch medical file');
    }
  }
}