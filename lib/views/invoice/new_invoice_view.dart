import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/examination/examination_fields.dart';
import '../../widgets/invoice/consultation_fee_card.dart';
import '../../widgets/invoice/extra_services_card.dart';
import '../../widgets/invoice/invoice_patient_card.dart';
import '../../widgets/invoice/invoice_summary_card.dart';

// ─── شاشة الفاتورة — أجرة الكشف + خدمات إضافية اختيارية ───
class NewInvoiceView extends GetView<InvoiceController> {
  const NewInvoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.theme.cardColor,
        foregroundColor: context.theme.textTheme.bodyLarge?.color,
        elevation: 0,
        surfaceTintColor: context.theme.cardColor,
        title: Text('New Invoice'.tr),
      ),
      body: SafeArea(
        child: Obx(() {
          // تفاصيل الموعد تحمل الأجرة، فلا معنى لرسم الفاتورة قبل وصولها
          if (controller.isLoading && controller.appointment.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InvoicePatientCard(),
                      const SizedBox(height: 20),
                      buildSectionTitle(context, 'Consultation Fee'.tr),
                      const SizedBox(height: 10),
                      const ConsultationFeeCard(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: buildSectionTitle(
                              context,
                              'Extra Services'.tr,
                            ),
                          ),
                          Obx(
                            () => controller.isSubmittingItem.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : buildAddLink(
                                    context,
                                    'Add Item'.tr,
                                    controller.addItem,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const ExtraServicesCard(),
                      const SizedBox(height: 20),
                      const InvoiceSummaryCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CustomButton(
                  text: 'Done'.tr,
                  onPressed: controller.closeInvoice,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
