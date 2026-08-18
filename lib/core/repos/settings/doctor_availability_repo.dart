import 'dart:convert';

import 'package:get/get.dart';

import '../../../models/settings/availability_item_model.dart';
import '../../../models/settings/available_period_model.dart';
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

    if (response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(
        decodedJson['message'] ?? 'Time conflict or invalid data.',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }

    return DoctorAvailabilityModel.fromJson(decodedJson);
  }

  Future<List<AvailabilityItemModel>> getAvailabilities(int doctorId) async {
    final response = await api.getAvailabilities(doctorId);
    final decodedJson = jsonDecode(_cleanJson(response.body));

    if (response.statusCode == 200) {
      final List data = decodedJson['availabilities'] ?? decodedJson['data'] ?? [];
      return data.map((e) => AvailabilityItemModel.fromJson(e)).toList();
    } else {
      throw Exception(
        decodedJson['message'] ?? 'Failed to load availabilities',
      );
    }
  }
  Future<List<AvailablePeriodModel>> fetchAvailableWorkingPeriods() async {
    final response = await api.getAvailableWorkingPeriods();
    final decodedJson = jsonDecode(_cleanJson(response.body));

    if (response.statusCode == 200 && decodedJson['status'] == 'success') {
      final List data = decodedJson['available_periods'] ?? [];
      return data.map((e) => AvailablePeriodModel.fromJson(e)).toList();
    } else {
      throw Exception(
        decodedJson['message'] ?? 'Failed to load free periods',
      );
    }
  }

  Future<String> deleteAvailability(int id) async {
    final response = await api.deleteAvailability(id);

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) return 'Deleted successfully'.tr;

      try {
        final decoded = jsonDecode(_cleanJson(response.body));
        if (decoded is Map) {
          return decoded['message']?.toString() ?? 'Deleted successfully'.tr;
        }
      } catch (_) {}
      return 'Deleted successfully'.tr;
    } else {
      String errorMessage = '${'Server error'.tr}: ${response.statusCode}';

      try {
        final decoded = jsonDecode(_cleanJson(response.body));

        if (decoded is Map && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        } else if (decoded is Map && decoded['errors'] != null) {
          errorMessage = decoded['errors'].values.first[0].toString();
        }
      } catch (_) {
        if (response.statusCode == 422) {
          errorMessage = 'Cannot delete this availability'.tr;
        }
      }

      throw errorMessage;
    }
  }

  Future<String> deleteAppointmentsByDate(String date) async {
    final res = await api.deleteAppointmentsByDate(date);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(_cleanJson(res.body));
      return decoded['message'] ?? 'Deleted successfully'.tr;
    } else {
      final decoded = jsonDecode(_cleanJson(res.body));
      throw Exception(decoded['message'] ?? 'Failed to delete appointments'.tr);
    }
  }

}
