// File: lib/controllers/growth/child_growth_controller.dart
import 'package:get/get.dart';
import '../../core/repos/growth/child_growth_repo.dart';
import '../../models/growth/child_growth_response_model.dart';
import '../base_controller.dart';

class ChildGrowthController extends BaseController {
  final ChildGrowthRepo repo;

  ChildGrowthController({required this.repo});

  late int childId;
  final Rxn<ChildGrowthResponseModel> growthData = Rxn<ChildGrowthResponseModel>();

  @override
  void onInit() {
    super.onInit();
    // سيتم تمرير الـ childId من الواجهة الأب (MedicalFileView)
  }

  /// جلب بيانات النمو والمخطط من السيرفر (GET)
  Future<void> getGrowthDashboard() async {
    showLoading();
    try {
      final result = await repo.fetchChildGrowthData(childId);
      growthData.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}