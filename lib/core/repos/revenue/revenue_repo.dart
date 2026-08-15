import 'dart:convert';
import '../../apis/revenue/revenue_api.dart';

class RevenueRepo {
  final RevenueApi api;
  RevenueRepo({required this.api});

  String _cleanJson(String response) {
    final brace = response.indexOf('{');
    final bracket = response.indexOf('[');
    if (bracket != -1 && (brace == -1 || bracket < brace)) {
      return response.substring(bracket);
    }
    if (brace != -1) return response.substring(brace);

    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);

    return response;
  }

  /// Month names exactly as the backend spells them. They come back in English
  /// even under `Accept-Language: ar`, so they are only used to sanity-check the
  /// ordering here — the label shown to the user is derived from the index.
  static const _monthOrder = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Current month's total earnings for the logged-in doctor.
  ///
  /// Independent from [getYearlyIncome]: this counts appointments whose
  /// `payment_status` is paid, while the yearly breakdown counts appointments
  /// whose `status` is completed. The two will often disagree for the current
  /// month, so never derive one from the other.
  Future<double> getMonthlyRevenue() async {
    final res = await api.getMonthlyIncome();
    return double.tryParse(
            jsonDecode(_cleanJson(res))['monthly_income']?.toString() ?? '0') ??
        0.0;
  }

  /// The current year's earnings per month — always 12 values in calendar
  /// order, January → December, with months that have no income (including
  /// future ones) as 0.
  Future<List<double>> getYearlyIncome() async {
    final decoded = jsonDecode(_cleanJson(await api.getYearlyIncome()));
    final values = List<double>.filled(12, 0.0);
    if (decoded is! List) return values;

    for (int i = 0; i < decoded.length && i < 12; i++) {
      final item = decoded[i];
      if (item is! Map) continue;
      // Trust the month name when we recognise it, fall back to the position.
      final month = _monthOrder.indexOf(item['month']?.toString() ?? '');
      values[month == -1 ? i : month] =
          double.tryParse(item['total_income']?.toString() ?? '') ?? 0.0;
    }
    return values;
  }

  // ─── Mock data — swap this body for a real API call when backend is ready ───

  Future<int> getTotalPaidVisits() async {
    // await api.getTotalPaidVisits();
    return 156;
  }
}
