import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../../widgets/home/floating_bottom_bar.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/next_patient_card.dart';
import '../../widgets/home/remaining_patients_list.dart';
import '../../widgets/home/stats_grid.dart';
import '../settings/settings_view.dart';


import '../schedule/schedule_view.dart';
import '../schedule/patients_view.dart';
import '../revenue/revenue_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});


  static const List<Widget> _tabs = [
    _DashboardTab(),        // Index 0: الرئيسية
    ScheduleView(),         // Index 1: الجدول
    PatientsView(),         // Index 2: المرضى
    RevenueView(),          // Index 3: الأرباح
    SettingsView(),         // Index 4: الإعدادات
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: const FloatingBottomBar(),
      body: Obx(() => _tabs[controller.currentIndex.value]),
    );
  }
}

// ─── كلاس لوحة التحكم الافتراضية المعزول ───
class _DashboardTab extends GetView<HomeController> {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.doctorData.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchAllDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const NextPatientCard(),
                    //const SizedBox(height: 24),
                    const StatsGrid(),
                    const SizedBox(height: 24),

                    // زر اختيار التاريخ
                    InkWell(
                      onTap: () => controller.selectCustomDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              controller.displaySelectedDate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Current Patients'.tr,
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const RemainingPatientsList(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}