import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    //القاموس الإنجليزي
    'en_US': {
      // --- Login View ---
      'Doctor Login': 'Doctor Login',
      'Welcome back to Clinic Management System':
          'Welcome back to Clinic Management System',
      'Mobile Number': 'Mobile Number',
      'Please enter mobile number': 'Please enter mobile number',
      'Invalid mobile number': 'Invalid mobile number',
      'Password': 'Password',
      'Please enter password': 'Please enter password',
      'Login': 'Login',
      'Success': 'Success',
      'Error': 'Error',

      // --- Home View ---
      'Hello': 'Hello',
      'Today': 'Today',
      'Appointments': 'Appointments',
      'Remaining Patients': 'Remaining Patients',
      'No remaining patients for today': 'No remaining patients for today',
      'Cancel': 'Cancel',
      'Done': 'Done',
      'male': 'Male',
      'female': 'Female',
      'Total': 'Total',
      'Home': 'Home',
      'Revenue': 'Revenue',
      'Profile': 'Profile',
      "Today's Total": "Today's Total",
      'Completed': 'Completed',
      'Monthly Rev': 'Monthly Rev',
      'Schedule': 'Schedule',
      'Settings': 'Settings',
      'No remaining patients for this date':
          'No remaining patients for this date',
      'Patients': 'Patients',
    },

    // القاموس العربي
    'ar_SY': {
      // --- Login View ---
      'Doctor Login': 'تسجيل دخول الطبيب',
      'Welcome back to Clinic Management System':
          'مرحباً بك مجدداً في نظام إدارة العيادة',
      'Mobile Number': 'رقم الموبايل',
      'Please enter mobile number': 'الرجاء إدخال رقم الموبايل',
      'Invalid mobile number': 'رقم الموبايل غير صالح',
      'Password': 'كلمة المرور',
      'Please enter password': 'الرجاء إدخال كلمة المرور',
      'Login': 'تسجيل الدخول',
      'Success': 'نجاح',
      'Error': 'خطأ',

      // --- Home View ---
      'Hello': 'مرحباً',
      'Today': 'اليوم',
      'Appointments': 'مواعيد',
      'Remaining Patients': 'المرضى المتبقين',
      'No remaining patients for today': 'لا يوجد مرضى متبقين لهذا اليوم',
      'Cancel': 'إلغاء',
      'Done': 'إتمام',
      'male': 'ذكر',
      'female': 'أنثى',
      'Total': 'الكلي',
      'Home': 'الرئيسية',
      'Revenue': 'الأرباح',
      'Profile': 'الحساب',
      "Today's Total": "إجمالي اليوم",
      'Completed': 'المكتملة',
      'Monthly Rev': 'أرباح الشهر',
      'Schedule': 'الجدول',
      'Settings': 'الإعدادات',
      'No remaining patients for this date': 'لا يوجد مرضى متبقين لهذا التاريخ',
      'Patients': 'المرضى',
    },
  };
}
