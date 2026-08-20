// File: lib/core/repos/growth/child_growth_repo.dart
import 'dart:convert';
import '../../../models/growth/child_growth_response_model.dart';
import '../../apis/growth/child_growth_api.dart';

class ChildGrowthRepo {
  final ChildGrowthApi api;

  ChildGrowthRepo({ChildGrowthApi? api}) : api = api ?? ChildGrowthApi();

  /// 1. معالجة بيانات مخطط النمو (GET)
  Future<ChildGrowthResponseModel> fetchChildGrowthData(int childId) async {
    final response = await api.getGrowthData(childId);

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        String cleanRes = response.body;
        if (cleanRes.contains('{')) {
          cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
        }
        final Map<String, dynamic> decodedData = json.decode(cleanRes);

        // التحقق مما إذا كانت البيانات داخل 'data' أم مباشرة في الجذر
        final targetData = decodedData.containsKey('who_standards')
            ? decodedData
            : (decodedData['data'] ?? decodedData);

        return ChildGrowthResponseModel.fromJson(targetData);
      } catch (e, stacktrace) {
        print('❌ Parsing Error: $e');
        print(stacktrace);
        throw Exception('Data Parsing Error: $e');
      }
    } else {
      // إجبار التطبيق على عرض رسالة السيرفر إذا كان هناك خطأ
      throw Exception(_parseError(response.body, response.statusCode));
    }
  }

  /// مساعدة لقراءة تفاصيل الخطأ بدقة
  String _parseError(String responseBody, int statusCode) {
    try {
      String cleanRes = responseBody;
      if (cleanRes.contains('{')) {
        cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
      }
      final decoded = json.decode(cleanRes);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'];
      }
    } catch (_) {}
    return 'Server Error $statusCode. Route might require different permissions.';
  }
}