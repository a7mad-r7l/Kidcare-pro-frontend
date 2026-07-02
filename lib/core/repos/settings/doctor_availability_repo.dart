import 'dart:convert';

import '../../../models/settings/doctor_availability_model.dart';
import '../../apis/settings/doctor_availability_api.dart';



class DoctorAvailabilityRepo {
  final DoctorAvailabilityApi api;
  DoctorAvailabilityRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) {
      return response.substring(response.indexOf('{'));
    }
    return response;
  }

  Future<DoctorAvailabilityModel> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await api.addAvailability(
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );

    final cleanedBody = _cleanJson(response.body);
    final Map<String, dynamic> decodedJson = jsonDecode(cleanedBody);

    // ─── التقاط خطأ التضارب 422 الموضح في البوست مان وتمريره للـ BaseController ───
    if (response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(decodedJson['message'] ?? 'Time conflict or invalid data.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }

    return DoctorAvailabilityModel.fromJson(decodedJson);
  }
}