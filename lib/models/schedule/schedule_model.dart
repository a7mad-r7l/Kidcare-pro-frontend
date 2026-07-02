class ScheduleDataModel {
  final int totalAppointments;
  final List<ScheduleAppointmentModel> appointments;

  ScheduleDataModel({required this.totalAppointments, required this.appointments});

  factory ScheduleDataModel.fromJson(Map<String, dynamic> json) {
    // قراءة المصفوفة من داخل كائن data
    var list = json['appointments'] as List? ?? [];
    return ScheduleDataModel(
      totalAppointments: int.tryParse(json['total_appointments']?.toString() ?? '0') ?? 0,
      appointments: list.map((e) => ScheduleAppointmentModel.fromJson(e)).toList(),
    );
  }
}

class ScheduleAppointmentModel {
  final int id;
  final String patientName;
  final int age;
  final String gender;
  final String image;
  final String time;
  final String timePeriod; // يتم حسابها برمجياً
  final String duration;
  final String note;
  final String status;

  ScheduleAppointmentModel({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.image,
    required this.time,
    required this.timePeriod,
    required this.duration,
    required this.note,
    required this.status,
  });

  factory ScheduleAppointmentModel.fromJson(Map<String, dynamic> json) {
    String rawTime = json['time']?.toString() ?? '00:00';
    String parsedTime = rawTime;
    String period = 'AM';

    // عملية حساب فترة الوقت وتنسيق الساعة
    try {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        period = hour >= 12 ? 'PM' : 'AM';
        hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        String hourStr = hour.toString().padLeft(2, '0');
        parsedTime = '$hourStr:${parts[1]}';
      }
    } catch (e) {
      parsedTime = rawTime;
    }

    // ─── استخراج المسار النسبي للصورة لتفادي تعارض الـ Localhost ───
    String rawImage = json['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return ScheduleAppointmentModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      patientName: json['patient_name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',

      // تمرير قيمة الصورة المنظفة
      image: rawImage,

      time: parsedTime,
      timePeriod: period,
      status: json['status']?.toString() ?? 'pending',

      // قيم افتراضية لعدم إرسالها من الباك إند
      duration: json['duration']?.toString() ?? '30',
      note: json['note']?.toString() ?? '',
    );
  }
}