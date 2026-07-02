import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/schedule/schedule_repo.dart';
import '../../models/schedule/schedule_model.dart';
import '../base_controller.dart';

class ScheduleController extends BaseController {
  final ScheduleRepo repo;
  ScheduleController({required this.repo});

  final selectedDate = DateTime.now().obs;
  final scheduleData = Rxn<ScheduleDataModel>();
  final weekDates = <DateTime>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  // عملية جلب الأيام المتاحة والمواعيد معاً
  Future<void> fetchInitialData() async {
    showLoading();
    try {
      final days = await repo.getWorkingDays();
      weekDates.assignAll(days);

      if (weekDates.isNotEmpty) {
        // تحديد أول يوم عمل تلقائياً
        selectedDate.value = weekDates.first;
        // جلب مواعيد اليوم الأول بدون إظهار لودينج متداخل
        await fetchScheduleForDate(selectedDate.value, showLoad: false);
      } else {
        hideLoading();
      }
    } catch (e) {
      handleError(e);
      hideLoading();
    }
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
    fetchScheduleForDate(date);
  }

  Future<void> fetchScheduleForDate(DateTime date, {bool showLoad = true}) async {
    if (showLoad) showLoading();
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final data = await repo.getSchedule(formattedDate);
      scheduleData.value = data;
    } catch (e) {
      handleError(e);
      scheduleData.value = ScheduleDataModel(totalAppointments: 0, appointments: []);
    } finally {
      if (showLoad) hideLoading();
    }
  }

  String getDayName(DateTime date) {
    return DateFormat('EEEE', Get.locale?.languageCode ?? 'en').format(date);
  }

  String getMonthName(DateTime date) {
    return DateFormat('MMMM', Get.locale?.languageCode ?? 'en').format(date);
  }
}