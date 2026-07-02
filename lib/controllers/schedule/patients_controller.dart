import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/schedule/patients_repo.dart';
import '../../models/schedule/patient_list_model.dart';
import '../base_controller.dart';

class PatientsController extends BaseController {
  final PatientsRepo repo;
  PatientsController({required this.repo});

  final patientsList = <PatientListModel>[].obs;
  final searchController = TextEditingController();
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchPatients();
  }

  Future<void> fetchPatients({String? query}) async {
    showLoading();
    try {
      final data = await repo.getPatients(query: query);
      patientsList.assignAll(data);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchPatients(query: query);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}