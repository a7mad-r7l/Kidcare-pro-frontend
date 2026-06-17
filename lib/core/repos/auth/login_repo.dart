import 'dart:convert';

import '../../../models/auth/login_model.dart';
import '../../apis/auth/login_api.dart';

class LoginRepo {
  final LoginApi api;
  LoginRepo({required this.api});

  Future<LoginModel> login({required String phone, required String password}) async {
    String rawResponse = await api.login(phone: phone, password: password);

    if (rawResponse.contains('{')) {
      rawResponse = rawResponse.substring(rawResponse.indexOf('{'));
    }

    final Map<String, dynamic> decodedJson = jsonDecode(rawResponse);
    return LoginModel.fromJson(decodedJson);
  }
}