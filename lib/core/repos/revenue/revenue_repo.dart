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

  /// Current month's total earnings for the logged-in doctor.
  Future<double> getMonthlyRevenue() async {
    final res = await api.getMonthlyIncome();
    return double.tryParse(
            jsonDecode(_cleanJson(res))['monthly_income']?.toString() ?? '0') ??
        0.0;
  }

  // ─── Mock data — swap these bodies for real API calls when backend is ready ──

  Future<int> getTotalPaidVisits() async {
    // await api.getTotalPaidVisits();
    return 156;
  }

  /// Revenue values for the chart (one per day of the month).
  /// Fluctuates up and down while trending upward, peaking at the 15,600
  /// monthly total shown in the header.
  Future<List<double>> getRevenueChartData() async {
    // await api.getRevenueChartData();
    return [
      1500, 3200, 2400, 4800, 3600, 6200, 4500,
      7400, 5800, 8600, 6900, 9800, 7600, 10900,
      8400, 11800, 9200, 12600, 10100, 13400, 10800,
      14100, 11500, 14800, 12200, 13600, 12900, 14500,
      15600,
    ];
  }
}
