import 'package:flutter/material.dart';
import 'lab_requests_card.dart';
import 'medications_card.dart';

// ─── تبويب الوصفة (بطاقة الأدوية + بطاقة التحاليل والأشعة) ───
class PrescriptionTab extends StatelessWidget {
  const PrescriptionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicationsCard(),
          SizedBox(height: 16),
          LabRequestsCard(),
        ],
      ),
    );
  }
}
