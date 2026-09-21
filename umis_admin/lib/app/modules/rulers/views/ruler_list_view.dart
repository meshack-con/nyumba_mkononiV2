import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/storage/storage_service.dart';
import '../controllers/ruler_list_controller.dart';
import '../widgets/ruler_avatar.dart';
import 'ruler_form_view.dart';
import 'ruler_profile_dialog.dart';
import 'ruler_quick_add_dialog.dart';

class RulerListView extends GetView<RulerListController> {
  const RulerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Wanachama',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Wanachama',
            subtitle: 'Tafuta, tazama na simamia taarifa za wanachama.',
          ),
          const SizedBox(height: 16),
          _Toolbar(controller: controller),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => controller.loadRulers(),
                        child: const Text('Jaribu tena'),
                      ),
                    ],
                  ),
                );
              }
              if (controller.rulers.isEmpty) {
                return const EmptyStateWidget(icon: Icons.people_outline, title: 'Hakuna Wanachama', subtitle: 'Hakuna wanachama waliopatikana - jaribu kubadilisha vigezo vya utafutaji.');
              }
              return _RulersTable(controller: controller);
            }),
          ),
          const SizedBox(height: 10),
          _Pagination(controller: controller),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final RulerListController controller;
  const _Toolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 380,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Jina / membership code / simu / kitambulisho',
                isDense: true,
              ),
              onSubmitted: controller.onSearchChanged,
            ),
          ),
          Obx(
            () => DropdownButton<String?>(
              value: controller.roleFilter.value,
              hint: const Text('Wote'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null, child: Text('Wote')),
                DropdownMenuItem(value: 'leader', child: Text('Viongozi')),
                DropdownMenuItem(value: 'member', child: Text('Wanachama wa Kawaida')),
              ],
              onChanged: controller.setRoleFilter,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final saved = await Get.dialog<bool>(const RulerQuickAddDialog());
              if (saved == true) controller.loadRulers(resetPage: false);
            },
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Ongeza Mwanachama'),
          ),
        ],
      ),
    );
  }
}

class _RulersTable extends StatelessWidget {
  final RulerListController controller;
  const _RulersTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTableCard(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Jina')),
          DataColumn(label: Text('Mkoa')),
          DataColumn(label: Text('Tawi')),
          DataColumn(label: Text('Jinsia')),
          DataColumn(label: Text('Nafasi au Cheo')),
          DataColumn(label: Text('Simu')),
          DataColumn(label: Text('Vitendo')),
        ],
        rows: controller.rulers.map((r) {
          return DataRow(cells: [
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              RulerAvatar(rulerId: r.id!, radius: 15),
              const SizedBox(width: 9),
              Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
            ])),
            DataCell(Text(r.regionName ?? '-')),
            DataCell(Text(r.instituteName ?? '-')),
            DataCell(Text(r.gender ?? '-')),
            DataCell(Text(r.currentPositionTitle ?? 'Mwanachama wa Kawaida')),
            DataCell(Text(r.phoneNumber ?? '-')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.key_outlined,
                    size: 18,
                    color: r.hasLoginAccount ? AppColors.success : AppColors.neutralGray,
                  ),
                  tooltip: r.hasLoginAccount ? 'Ana Akaunti - Badilisha Password' : 'Hana Akaunti - Tengeneza Akaunti',
                  onPressed: () => _showPasswordDialog(context, r),
                ),
                // NB: "Profile Kamili", "Hariri", na "Futa" ni ruhusa za
                // ADMIN/USER TU (angalia backend app/ruler/router.py) -
                // zinafichwa kwa mtumiaji wa role "MSAJILI" pekee ili
                // asione kitufe ambacho kitampa "Huna ruhusa" (403).
                if (!Get.find<StorageService>().isMsajiliOnly) ...[
                  IconButton(
                    icon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.info),
                    tooltip: 'Profile Kamili',
                    onPressed: () => Get.dialog(RulerProfileDialog(rulerId: r.id!, rulerName: r.fullName)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                    tooltip: 'Hariri',
                    onPressed: () async {
                      final saved = await Get.dialog<bool>(RulerFormDialog(rulerId: r.id));
                      if (saved == true) controller.loadRulers(resetPage: false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    tooltip: 'Futa',
                    onPressed: () => _confirmDelete(context, r.id!, r.fullName),
                  ),
                ],
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Future<void> _showAccountCreatedDialog(({String? membershipCode, String defaultPassword}) result) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Akaunti ya Kuingia Imeundwa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mwambie mwanachama huyu atumie taarifa hizi kuingia Mobile App:'),
            const SizedBox(height: 14),
            _CredentialTile(label: 'Username (Membership No)', value: result.membershipCode ?? '-'),
            const SizedBox(height: 8),
            _CredentialTile(label: 'Password ya Awali', value: result.defaultPassword),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Sawa, Nimeelewa')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPasswordDialog(BuildContext context, dynamic ruler) {
    final newPasswordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(ruler.hasLoginAccount ? 'Badilisha Password - ${ruler.fullName}' : 'Tengeneza Akaunti - ${ruler.fullName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ruler.hasLoginAccount
                    ? 'Mwanachama huyu tayari ana akaunti. Unaweza kumwekea password maalum, AU kumtengenezea moja ya kiotomatiki (Jina la Mwisho).'
                    : 'Mwanachama huyu hana akaunti bado. Weka password maalum, au bofya "Tengeneza Kiotomatiki" chini.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(controller: newPasswordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Mpya (Maalum)')),
              const SizedBox(height: 10),
              TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Thibitisha Password')),
              const SizedBox(height: 14),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    Get.back();
                    final result = await controller.generateLoginAccount(ruler.id!);
                    if (result != null) await _showAccountCreatedDialog(result);
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Au Tengeneza Kiotomatiki (Jina la Mwisho)'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordCtrl.text.length < 6) {
                Get.snackbar('Kosa', 'Password iwe angalau herufi 6.', snackPosition: SnackPosition.BOTTOM);
                return;
              }
              if (newPasswordCtrl.text != confirmCtrl.text) {
                Get.snackbar('Kosa', 'Password hazifanani.', snackPosition: SnackPosition.BOTTOM);
                return;
              }
              final ok = await controller.resetRulerPassword(ruler.id!, newPasswordCtrl.text);
              if (ok) Get.back();
            },
            child: const Text('Hifadhi Password'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa Mwanachama'),
        content: Text('Una uhakika unataka kumfuta "$name"? Kitendo hiki hakiwezi kutenguliwa.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.deleteRuler(id);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final RulerListController controller;
  const _Pagination({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Ukurasa ${controller.currentPage.value}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: controller.currentPage.value > 1 ? controller.previousPage : null,
            child: const Text('Iliyotangulia'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: controller.hasMore.value ? controller.nextPage : null,
            child: const Text('Inayofuata'),
          ),
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final String label;
  final String value;
  const _CredentialTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Nakili',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar('Imenakiliwa', '"$value" imenakiliwa.', snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
    );
  }
}
