import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../controllers/users_controller.dart';

class UsersView extends GetView<UsersController> {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Watumiaji wa Mfumo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Watumiaji wa Mfumo',
                  subtitle: 'Hawa ndio watu wanaoingia (login) kusimamia Admin Panel.',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showUserDialog(context),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Ongeza Mtumiaji'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 340,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Jina, username, simu au roles...',
                isDense: true,
              ),
              onChanged: (v) => controller.searchText.value = v,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: controller.loadUsers, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              final list = controller.filteredUsers;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchText.value.isEmpty ? 'Hakuna watumiaji bado.' : 'Hakuna matokeo.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Jina')),
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Simu')),
                    DataColumn(label: Text('Majukumu')),
                    DataColumn(label: Text('Hali')),
                    DataColumn(label: Text('Vitendo')),
                  ],
                  rows: list.map((u) {
                    return DataRow(cells: [
                      DataCell(Text(u.fullName.isEmpty ? '-' : u.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(u.username)),
                      DataCell(Text(u.phoneNumber ?? '-')),
                      DataCell(Text(u.roles)),
                      DataCell(StatusBadge.active(!u.isBlocked)),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                          tooltip: 'Hariri',
                          onPressed: () => _showUserDialog(context, existing: u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.key_outlined, size: 18, color: AppColors.info),
                          tooltip: 'Weka Password Mpya (Reset)',
                          onPressed: () => _showResetPasswordDialog(context, u),
                        ),
                        IconButton(
                          icon: Icon(
                            u.isBlocked ? Icons.lock_open_outlined : Icons.lock_outline,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          tooltip: u.isBlocked ? 'Fungua (Unblock)' : 'Zuia (Block)',
                          onPressed: () => controller.toggleBlocked(u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          tooltip: 'Futa',
                          onPressed: () => _confirmDelete(context, u),
                        ),
                      ])),
                    ]);
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, UserModel user) {
    final newPasswordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Weka Password Mpya - ${user.username}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hii itaweka password mpya kwa mtumiaji huyu moja kwa moja '
                '(hauitaji password yake ya zamani). Mwambie password mpya kwa njia salama.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Mpya'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Thibitisha Password Mpya'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      if (newPasswordCtrl.text.length < 6) {
                        Get.snackbar('Kosa', 'Password iwe angalau herufi 6.', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      if (newPasswordCtrl.text != confirmCtrl.text) {
                        Get.snackbar('Kosa', 'Password hazifanani.', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final ok = await controller.resetPassword(user.id, newPasswordCtrl.text);
                      if (ok) Get.back();
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Weka Password'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa Mtumiaji'),
        content: Text('Una uhakika unataka kumfuta "${user.username}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.deleteUser(user.id);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(BuildContext context, {UserModel? existing}) {
    final firstNameCtrl = TextEditingController(text: existing?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: existing?.lastName ?? '');
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
    final passwordCtrl = TextEditingController();
    final selectedRoles = RxList<String>(existing?.roleList ?? <String>[]);

    Get.dialog(
      AlertDialog(
        title: Text(existing == null ? 'Ongeza Mtumiaji' : 'Hariri Mtumiaji'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'Jina la Kwanza')),
                const SizedBox(height: 10),
                TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Jina la Mwisho')),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameCtrl,
                  enabled: existing == null, // username haibadiliki baada ya kuundwa
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Simu')),
                if (existing == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                ],
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Roles', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                Obx(
                  () => Column(
                    children: [
                      CheckboxListTile(
                        value: selectedRoles.contains('ADMIN'),
                        title: const Text('ADMIN'),
                        onChanged: (v) => v == true ? selectedRoles.add('ADMIN') : selectedRoles.remove('ADMIN'),
                      ),
                      CheckboxListTile(
                        value: selectedRoles.contains('USER'),
                        title: const Text('USER'),
                        onChanged: (v) =>
                            v == true ? selectedRoles.add('USER') : selectedRoles.remove('USER'),
                      ),
                      CheckboxListTile(
                        value: selectedRoles.contains('MSAJILI'),
                        title: const Text('MSAJILI'),
                        subtitle: const Text('Anaweza kusajili/kuona Wanachama TU - hana ruhusa nyingine.', style: TextStyle(fontSize: 11.5)),
                        onChanged: (v) =>
                            v == true ? selectedRoles.add('MSAJILI') : selectedRoles.remove('MSAJILI'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      bool ok;
                      if (existing == null) {
                        if (usernameCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
                          Get.snackbar('Kosa', 'Username na password ni lazima.', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        ok = await controller.createUser(
                          username: usernameCtrl.text.trim(),
                          password: passwordCtrl.text,
                          firstName: firstNameCtrl.text.trim(),
                          lastName: lastNameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                          roles: selectedRoles,
                        );
                      } else {
                        ok = await controller.updateUser(
                          existing.id,
                          firstName: firstNameCtrl.text.trim(),
                          lastName: lastNameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                          roles: selectedRoles,
                        );
                      }
                      if (ok) Get.back();
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Hifadhi'),
            ),
          ),
        ],
      ),
    );
  }
}
