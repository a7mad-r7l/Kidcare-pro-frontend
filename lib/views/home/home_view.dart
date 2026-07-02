import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/home_controller.dart';
import '../../core/constants.dart';

/// يبني رابط الصورة: يُرجع الرابط كما هو إن كان مطلقًا، وإلا يضيف [baseUrl].
String _imageUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$baseUrl/$path';
}

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // ─── تمديد جسم الشاشة خلف شريط التنقل لمنع الفراغات البيضاء ───
      extendBody: true,

      // ─── استدعاء الـ Custom Floating Bottom Navigation Bar ───
      bottomNavigationBar: _buildFloatingBottomBar(context),

      body: Obx(() {
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
                // الـ Curved Header الاحترافي الباقي كما هو وثابت
                _buildCurvedHeader(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ─── 1. الـ Next Patient أصبح في الأعلى أولاً ───
                      Text(
                        'Next Patient'.tr,
                        style: context.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(() => _buildNextPatientCard(context)),

                      const SizedBox(height: 24),

                      // ─── 2. الإحصائيات أصبحت أسفل الـ Next Patient وبعناوين واضحة ───
                      _buildStatsGrid(context),

                      const SizedBox(height: 24),

                      // ─── 3. شريط اختيار التاريخ فوق قائمة المرضى المتبقين ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining Patients'.tr,
                            style: context.theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          // زر محدد التاريخ الديناميكي المظهر للتاريخ الحالي
                          InkWell(
                            onTap: () => controller.selectCustomDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.theme.primaryColor.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                    color: context.theme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    controller.formattedSelectedDate,
                                    style: TextStyle(
                                      color: context.theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // قائمة المرضى المتبقين النظيفة والمحدثة
                      Obx(() => _buildRemainingPatientsList(context)),

                      // ─── مسافة عازلة إضافية لمنع البار العائم من تغطية آخر مريض ───
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── دالة بناء شريط التنقل السفلي العائم (Floating Bottom Bar) ───
  Widget _buildFloatingBottomBar(BuildContext context) {
    return Obx(() {
      return SafeArea(
        child: Container(
          height: 68,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context
                .theme
                .cardColor, // يتكيف تلقائياً مع الـ Dark/Light Mode
            borderRadius: BorderRadius.circular(
              24,
            ), // حواف دائرية انسيابية وفخمة
            boxShadow: [
              BoxShadow(
                color: context.theme.primaryColor.withOpacity(
                  0.12,
                ), // ظلال بلون هوية التطبيق تعطي عمقاً جذاباً
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(
                0.05,
              ), // حد خفيف للبروز المعماري
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_filled, 'Home'.tr),
              _buildNavItem(
                context,
                1,
                Icons.edit_calendar_outlined,
                'Schedule'.tr,
              ),
              _buildNavItem(
                context,
                2,
                Icons.people_alt_outlined,
                'Patients'.tr,
              ),
              _buildNavItem(context, 3, Icons.analytics_outlined, 'Revenue'.tr),
              _buildNavItem(context, 4, Icons.settings_outlined, 'Settings'.tr),
            ],
          ),
        ),
      );
    });
  }

  // ─── دالة بناء العنصر الفردي داخل الشريط مع اللمسة الحركية المخصصة ───
  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = controller.currentIndex.value == index;
    final activeColor = context.theme.primaryColor;
    final inactiveColor = context.theme.hintColor.withOpacity(0.4);

    return InkWell(
      onTap: () => controller.currentIndex.value = index,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          // ظهور خلفية دائرية خفيفة جداً بلون الهوية عند اختيار العنصر
          color: isSelected
              ? activeColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تأثير حركي لتكبير الأيقونة المحددة بسلاسة (Scale Animation)
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context) {
    final doctor = controller.doctorData.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 35),
      decoration: BoxDecoration(
        color: context.theme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: doctor != null && doctor.image.isNotEmpty
                ? NetworkImage(_imageUrl(doctor.image))
                : null,
            child: doctor == null || doctor.image.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor != null ? 'Dr. ${doctor.name}' : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor?.specialization ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildStatItem(
          context,
          "Today's Total".tr,
          controller.totalAppointments.value.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatItem(
          context,
          'Completed'.tr,
          controller.completedAppointments.value.toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        GestureDetector(
          onTap: () => Get.toNamed('/revenue'),
          child: _buildStatItem(
            context,
            'Monthly Rev'.tr,
            '\$${controller.monthlyRevenue.value.toStringAsFixed(0)}',
            Icons.monetization_on_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.04)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: context.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: context.theme.hintColor,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNextPatientCard(BuildContext context) {
    final patient = controller.nextPatient.value;
    if (patient == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No upcoming patients'.tr)),
      );
    }
    return GestureDetector(
      // فتح شاشة معاينة المريض مع تمرير بيانات المريض القادم
      onTap: () => Get.toNamed('/examination', arguments: patient),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.theme.primaryColor.withOpacity(0.85),
              context.theme.primaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: patient.image.isNotEmpty
                  ? NetworkImage(_imageUrl(patient.image))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${patient.age} Yrs • ${patient.gender.tr} • ${patient.appointmentTime}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: context.theme.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: () =>
                  controller.completePatientAppointment(patient.appointmentId),
              child: Text(
                'Done'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingPatientsList(BuildContext context) {
    if (controller.remainingPatients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(child: Text('No remaining patients for this date'.tr)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.remainingPatients.length,
      itemBuilder: (context, index) {
        final patient = controller.remainingPatients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: patient.image.isNotEmpty
                    ? NetworkImage(_imageUrl(patient.image))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.age} Yrs • ${patient.gender.tr} • ${patient.appointmentTime}',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 26,
                ),
                onPressed: () =>
                    controller.completePatientAppointment(patient.appointmentId),
              ),
            ],
          ),
        );
      },
    );
  }
}
