import '../../../models/revenue/transaction_model.dart';
import '../../apis/revenue/revenue_api.dart';

class RevenueRepo {
  final RevenueApi api;
  RevenueRepo({required this.api});

  // ─── Mock data — swap these bodies for real API calls when backend is ready ──

  Future<double> getMonthlyRevenue() async {
    // await api.getMonthlyRevenue();
    return 15600;
  }

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

  Future<List<TransactionModel>> getTransactions() async {
    // await api.getTransactions();
    return [
      TransactionModel(id: 1, patientName: 'آدم محمد',    date: '12 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 2, patientName: 'لينا خالد',   date: '12 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 3, patientName: 'يوسف عبدالله', date: '11 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 4, patientName: 'لينا محمد',   date: '11 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 5, patientName: 'سارة أحمد',   date: '10 مايو 2024', amount: 150, paymentMethod: 'stripe'),
    ];
  }
}
