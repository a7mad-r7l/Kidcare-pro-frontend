class AppointmentDetailsModel {
  final int appointmentId;
  final String date;
  final String day;
  final String time;
  final String status;
  final String consultationFee;
  final String currency;
  final String paymentStatus;

  final int childId;
  final String childName;
  final String childImage;
  final String childGender;
  final int childAge;
  final String childAgeType;

  // حقول وهمية مؤقتة لتطابق التصميم (يجب إضافتها من الباك إند لاحقاً)
  final String fileNumber;
  final String appointmentType;
  final String parentsNotes;

  AppointmentDetailsModel({
    required this.appointmentId,
    required this.date,
    required this.day,
    required this.time,
    required this.status,
    required this.consultationFee,
    required this.currency,
    required this.paymentStatus,
    required this.childId,
    required this.childName,
    required this.childImage,
    required this.childGender,
    required this.childAge,
    required this.fileNumber,
    required this.appointmentType,
    required this.parentsNotes, required this.childAgeType,
  });

  factory AppointmentDetailsModel.fromJson(Map<String, dynamic> json) {
    final child = json['child'] ?? {};

    // معالجة الوقت
    String rawTime = json['time']?.toString() ?? '00:00:00';
    String parsedTime = rawTime;
    try {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        String period = hour >= 12 ? 'PM' : 'AM';
        hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        parsedTime = '${hour.toString().padLeft(2, '0')}:${parts[1]} $period';
      }
    } catch (_) {}

    // ─── استخراج المسار النسبي للصورة لتفادي تعارض الـ Localhost ───
    String rawImage = child['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return AppointmentDetailsModel(
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      time: parsedTime,
      status: json['status']?.toString() ?? 'pending',
      consultationFee: json['consultation_fee']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? '\$',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',

      childId: int.tryParse(child['id']?.toString() ?? '0') ?? 0,
      childName: child['name']?.toString() ?? '',

      // تمرير قيمة الصورة المنظفة
      childImage: rawImage,

      childGender: child['gender']?.toString() ?? 'male',
      childAge: int.tryParse(child['age']?.toString() ?? '0') ?? 0,
      childAgeType: child['age_type']?.toString() ?? 'year',

      // تعيين قيم افتراضية للحقول الناقصة
      fileNumber: 'PT-2024-${json['appointment_id']}',
      appointmentType: 'Periodic checkup',
      parentsNotes: 'يعاني الطفل من سعال خفيف وارتفاع بدرجة الحرارة يرجى فحص الصدر والحلق.',
    );
  }
}