import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService;
  final StorageService _storage;

  LoginController(this._authService, this._storage);

  final formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();

  void toggleObscure() => obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    errorMessage.value = null;
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final result = await _authService.login(
        username: usernameCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      await _storage.saveToken(result.token);
      await _storage.saveUser(result.user.toJson());
      // Msajili (role "MSAJILI" TU) hana ruhusa ya kuona Dashboard (takwimu
      // za jumla za mfumo) - tunampeleka moja kwa moja kwenye "Wanachama"
      // (ndiyo kazi yake) badala ya ukurasa asioweza kuufikia.
      Get.offAllNamed(_storage.isMsajiliOnly ? AppRoutes.msajiliDashboard : AppRoutes.dashboard);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Hitilafu isiyotarajiwa. Jaribu tena.';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
