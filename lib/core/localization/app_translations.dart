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
    },
  };
}
