// ─── نماذج الفاتورة ───
// الفاتورة = أجرة الكشف (تُضبط عند الحجز) + خدمات إضافية اختيارية يضيفها الطبيب.
// الباك إند يرجع الأسعار أحياناً كنص ("50.00") وأحياناً كرقم (95) لذلك تُمرَّر كلها عبر _toNum.

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// تفاصيل الموعد — المصدر الوحيد لأجرة الكشف والعملة (لا يوجد مسار مستقل لها)
class AppointmentInvoiceModel {
  final int appointmentId;
  final String date;
  final String day;
  final String time;
  final String status;
  final num consultationFee;
  final String currency;
  final String paymentStatus;
  final InvoiceChildModel? child;

  AppointmentInvoiceModel({
    required this.appointmentId,
    required this.date,
    required this.day,
    required this.time,
    required this.status,
    required this.consultationFee,
    required this.currency,
    required this.paymentStatus,
    this.child,
  });

  factory AppointmentInvoiceModel.fromJson(Map<String, dynamic> json) {
    return AppointmentInvoiceModel(
      appointmentId: _toInt(json['appointment_id']),
      date: json['date']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      consultationFee: _toNum(json['consultation_fee']),
      currency: json['currency']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      child: json['child'] is Map<String, dynamic>
          ? InvoiceChildModel.fromJson(json['child'])
          : null,
    );
  }
}

class InvoiceChildModel {
  final int id;
  final String name;
  final String image;
  final String gender;
  final int age;

  InvoiceChildModel({
    required this.id,
    required this.name,
    required this.image,
    required this.gender,
    required this.age,
  });

  factory InvoiceChildModel.fromJson(Map<String, dynamic> json) {
    return InvoiceChildModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'male',
      age: _toInt(json['age']),
    );
  }
}

// خدمة إضافية واحدة — يُحفظ id لأنه المعرف المطلوب للحذف
class AdditionModel {
  final int id;
  final int appointmentId;
  final String itemName;
  final num price;

  AdditionModel({
    required this.id,
    required this.appointmentId,
    required this.itemName,
    required this.price,
  });

  factory AdditionModel.fromJson(Map<String, dynamic> json) {
    return AdditionModel(
      id: _toInt(json['id']),
      appointmentId: _toInt(json['appointment_id']),
      itemName: json['item_name']?.toString() ?? '',
      price: _toNum(json['price']),
    );
  }
}

// الفاتورة الكاملة كما يرجعها الخادم بعد كل إضافة أو حذف —
// ترسم الشاشة منها مباشرة دون إعادة جلب.
class InvoiceModel {
  final int appointmentId;
  final num appointmentPrice;
  final List<AdditionModel> additions;
  final num totalAdditions;
  final num finalPrice;

  InvoiceModel({
    required this.appointmentId,
    required this.appointmentPrice,
    required this.additions,
    required this.totalAdditions,
    required this.finalPrice,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawAdditions = json['additions'] as List? ?? [];
    return InvoiceModel(
      appointmentId: _toInt(json['appointment_id']),
      appointmentPrice: _toNum(json['appointment_price']),
      additions: rawAdditions
          .whereType<Map<String, dynamic>>()
          .map(AdditionModel.fromJson)
          .toList(),
      totalAdditions: _toNum(json['total_additions']),
      finalPrice: _toNum(json['final_price']),
    );
  }
}
