import 'dart:convert';
import '../../../models/profile/doctor_profile_model.dart';
import '../../apis/profile/doctor_profile_api.dart';

class DoctorProfileRepo {
  final DoctorProfileApi _api = DoctorProfileApi();

  String _cleanJson(String response) {
    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);
    return response;
  }

  Future<DoctorProfileModel> getProfile() async {
    final response = await _api.getProfile();
    final body = jsonDecode(_cleanJson(response));

    if (body['status'] == 'success') {
      return DoctorProfileModel.fromJson(body);
    }
    throw Exception(body['message'] ?? 'Failed to load profile');
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.updateProfile(data);
    final body = jsonDecode(_cleanJson(response));

    if (body['status'] == 'success') {
      return;
    }
    throw Exception(body['message'] ?? 'Failed to update profile');
  }
}
