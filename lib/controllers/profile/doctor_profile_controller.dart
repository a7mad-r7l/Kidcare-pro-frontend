
import 'package:get/get.dart';
import '../../core/repos/profile/doctor_profile_repo.dart';
import '../../models/profile/doctor_profile_model.dart';
import '../base_controller.dart';
import '../home/home_controller.dart';

class DoctorProfileController extends BaseController {
  final DoctorProfileRepo repo;

  DoctorProfileController({required this.repo});

  final Rx<DoctorProfileModel?> profile = Rx<DoctorProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    showLoading();
    try {
      final result = await repo.getProfile();
      profile.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> updateProfileField(String key, dynamic newValue) async {
    if (newValue.toString().trim().isEmpty) return;

    showLoading();
    try {
      await repo.updateProfile({key: newValue});
      await fetchProfile();


      if ((key == 'first_name' || key == 'last_name') &&
          Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchAllDashboardData();
      }

      Get.back();
      showSuccess('Profile updated successfully'.tr);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
