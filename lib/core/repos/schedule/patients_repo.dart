import 'dart:convert';
import '../../../models/schedule/patient_list_model.dart';
import '../../apis/schedule/patients_api.dart';

class PatientsRepo {
  final PatientsApi api;
  PatientsRepo({required this.api});

  String _cleanJson(String response) {
    int curlyIndex = response.indexOf('{');
    int squareIndex = response.indexOf('[');
    if (curlyIndex == -1 && squareIndex == -1) return response;
    if (curlyIndex != -1 && squareIndex != -1) {
      int startIndex = curlyIndex < squareIndex ? curlyIndex : squareIndex;
      return response.substring(startIndex);
    }
    return curlyIndex != -1 ? response.substring(curlyIndex) : response.substring(squareIndex);
  }

  Future<List<PatientListModel>> getPatients({String? query}) async {
    final res = await api.getAllPatients(query: query);
    final decoded = jsonDecode(_cleanJson(res));

    if (decoded['status'] == true && decoded['patients'] != null) {
      final List list = decoded['patients'];
      return list.map((e) => PatientListModel.fromJson(e)).toList();
    }
    return [];
  }
}