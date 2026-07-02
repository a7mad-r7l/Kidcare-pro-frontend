import 'package:get/get.dart';
import '../../core/repos/schedule/appointment_details_repo.dart';
import '../../models/schedule/appointment_details_model.dart';
import '../base_controller.dart';

class AppointmentDetailsController extends BaseController {
  final AppointmentDetailsRepo repo;
  AppointmentDetailsController({required this.repo});

  final appointmentDetails = Rxn<AppointmentDetailsModel>();
  late final int appointmentId;

  @override
  void onInit() {
    super.onInit();
    // استلام الـ ID المرسل من شاشة الجدول
    appointmentId = Get.arguments as int? ?? 0;
    if (appointmentId != 0) {
      fetchDetails();
    }
  }

  Future<void> fetchDetails() async {
    showLoading();
    try {
      final data = await repo.getDetails(appointmentId);
      appointmentDetails.value = data;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}