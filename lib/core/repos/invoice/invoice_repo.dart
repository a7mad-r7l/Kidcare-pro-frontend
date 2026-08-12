import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/invoice/invoice_model.dart';
import '../../apis/invoice/invoice_api.dart';

class InvoiceRepo {
  final InvoiceApi api;
  InvoiceRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    if (response.contains('[')) return response.substring(response.indexOf('['));
    return response;
  }

  // الإضافة ترجع 201 لا 200، لذا يُقبل نطاق 2xx كاملاً.
  // عند الفشل يُرمى نص الجسم كما هو ليستخرج handleError رسالة الخادم منه.
  Map<String, dynamic> _decode(http.Response response) {
    final cleaned = _cleanJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(cleaned);
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  Future<AppointmentInvoiceModel> getAppointment(int appointmentId) async {
    final decoded = _decode(await api.getAppointment(appointmentId));
    return AppointmentInvoiceModel.fromJson(decoded['data'] ?? {});
  }

  Future<InvoiceModel> addAddition(
    int appointmentId, {
    required String itemName,
    required num price,
  }) async {
    final decoded = _decode(
      await api.addAddition(appointmentId, itemName: itemName, price: price),
    );
    return InvoiceModel.fromJson(decoded['appointment'] ?? {});
  }

  Future<InvoiceModel> deleteAddition(int additionId) async {
    final decoded = _decode(await api.deleteAddition(additionId));
    return InvoiceModel.fromJson(decoded['appointment'] ?? {});
  }
}
