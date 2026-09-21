import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentYellow),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    AppConfig.appName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  const Text(
                    AppConfig.appTagline,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ingia kwenye mfumo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Jina la Mtumiaji', hintText: 'Ingiza jina la mtumiaji'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Jina la mtumiaji linahitajika' : null,
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => TextFormField(
                      controller: controller.passwordCtrl,
                      obscureText: controller.obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: 'Nywila',
                        hintText: 'Ingiza nywila',
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: controller.toggleObscure,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Nywila inahitajika' : null,
                      onFieldSubmitted: (_) => controller.login(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.login,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Ingia'),
                      ),
                    ),
                  ),
                  Obx(
                    () => controller.errorMessage.value == null
                        ? const SizedBox(height: 8)
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              controller.errorMessage.value!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
