import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/invoice/invoice_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../../models/invoice/invoice_model.dart';
import '../base_controller.dart';

class InvoiceController extends BaseController {
  final InvoiceRepo repo;

  InvoiceController({required this.repo});

  // تفاصيل الموعد (أجرة الكشف والعملة) — تُجلب عند فتح الشاشة
  final appointment = Rxn<AppointmentInvoiceModel>();

  // الفاتورة الحالية كما يرجعها الخادم بعد كل إضافة أو حذف
  final invoice = Rxn<InvoiceModel>();

  final serviceNameController = TextEditingController();
  final costController = TextEditingController();

  // مؤشرات تحميل منفصلة حتى لا يُقفل زر الحفظ أثناء إضافة خدمة
  final isSubmittingItem = false.obs;
  final deletingAdditionId = RxnInt();

  late final int appointmentId;

  // بيانات المريض الممرَّرة من شاشة المعاينة — تُرسم الترويسة فوراً قبل وصول الرد
  PatientModel? patient;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PatientModel) {
      patient = args;
      appointmentId = args.appointmentId;
    } else {
      appointmentId = args is int ? args : 0;
    }
    if (appointmentId != 0) fetchAppointment();
  }

  Future<void> fetchAppointment() async {
    showLoading();
    try {
      appointment.value = await repo.getAppointment(appointmentId);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── القيم المعروضة ───
  // تُفضَّل قيم الخادم متى توفرت (بعد أول إضافة)، وإلا فقيم تفاصيل الموعد.

  List<AdditionModel> get additions => invoice.value?.additions ?? const [];

  num get consultationFee =>
      invoice.value?.appointmentPrice ?? appointment.value?.consultationFee ?? 0;

  num get extrasTotal => invoice.value?.totalAdditions ?? 0;

  num get totalAmount => invoice.value?.finalPrice ?? consultationFee;

  String get currencySymbol {
    final code = appointment.value?.currency.toUpperCase() ?? '';
    return switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'INR' => '₹',
      'SYP' => 'ل.س',
      _ => code,
    };
  }

  String formatMoney(num value) =>
      '$currencySymbol ${value.toStringAsFixed(2)}'.trim();

  String get patientName =>
      appointment.value?.child?.name ?? patient?.name ?? '';

  String get patientImage =>
      appointment.value?.child?.image ?? patient?.image ?? '';

  // نفس صيغة معرف المريض المستخدمة في شاشة المعاينة ليتطابق العرض في الشاشتين
  String get formattedPatientId {
    final id = appointment.value?.child?.id ?? patient?.id ?? 0;
    return 'PT-${DateTime.now().year}-${id.toString().padLeft(4, '0')}';
  }

  String get formattedDate {
    final raw = appointment.value?.date ?? '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy', Get.locale?.toString()).format(parsed);
  }

  String get formattedTime {
    final raw = appointment.value?.time ?? patient?.appointmentTime ?? '';
    final parsed = DateTime.tryParse('2000-01-01 $raw');
    if (parsed == null) return raw;
    return DateFormat('hh:mm a', Get.locale?.toString()).format(parsed);
  }

  // ─── الخدمات الإضافية ───

  void clearServiceName() => serviceNameController.clear();

  // كل خدمة تُحفظ لحظة إضافتها، والرد يحمل الفاتورة كاملة فتُرسم منه مباشرة
  Future<void> addItem() async {
    final name = serviceNameController.text.trim();
    if (name.isEmpty) {
      showInfo('Please enter the service name'.tr);
      return;
    }

    final price = num.tryParse(costController.text.trim());
    if (price == null || price <= 0) {
      showInfo('Please enter a valid cost'.tr);
      return;
    }

    isSubmittingItem.value = true;
    try {
      invoice.value = await repo.addAddition(
        appointmentId,
        itemName: name,
        price: price,
      );
      serviceNameController.clear();
      costController.clear();
    } catch (e) {
      handleError(e);
    } finally {
      isSubmittingItem.value = false;
    }
  }

  // لا يوجد مسار تعديل — تغيير خدمة يتم بحذفها ثم إضافتها من جديد
  Future<void> deleteItem(AdditionModel addition) async {
    if (deletingAdditionId.value != null) return;
    deletingAdditionId.value = addition.id;
    try {
      invoice.value = await repo.deleteAddition(addition.id);
    } catch (e) {
      handleError(e);
    } finally {
      deletingAdditionId.value = null;
    }
  }

  // الخدمات تُحفظ لحظة إضافتها، فهذا الزر إغلاق للشاشة لا حفظ —
  // ويمنع الخروج بخدمة مكتوبة لم تُضَف حتى لا تضيع دون أن يشعر الطبيب.
  void closeInvoice() {
    final hasPendingItem =
        serviceNameController.text.trim().isNotEmpty ||
        costController.text.trim().isNotEmpty;
    if (hasPendingItem) {
      showInfo('Please add the service or clear the fields'.tr);
      return;
    }
    Get.back();
  }

  @override
  void onClose() {
    serviceNameController.dispose();
    costController.dispose();
    super.onClose();
  }
}
