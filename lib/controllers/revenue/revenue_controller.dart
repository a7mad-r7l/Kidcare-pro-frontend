import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/revenue/revenue_repo.dart';
import '../base_controller.dart';

class RevenueController extends BaseController {
  final RevenueRepo repo;
  RevenueController({required this.repo});

  final monthlyRevenue = 0.0.obs;
  final totalPaidVisits = 0.obs;

  /// One value per month of the current year, January → December.
  final yearlyIncome = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllRevenueData();
  }

  Future<void> fetchAllRevenueData() async {
    showLoading();
    await Future.wait([
      _run(() async => monthlyRevenue.value = await repo.getMonthlyRevenue()),
      _run(() async => totalPaidVisits.value = await repo.getTotalPaidVisits()),
      _run(() async => yearlyIncome.assignAll(await repo.getYearlyIncome())),
    ]);
    hideLoading();
  }

  Future<void> _run(Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      debugPrint('RevenueController error: $e');
    }
  }
}
