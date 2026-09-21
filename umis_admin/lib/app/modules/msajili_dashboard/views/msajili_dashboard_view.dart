import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../controllers/msajili_dashboard_controller.dart';

class MsajiliDashboardView extends StatefulWidget {
  const MsajiliDashboardView({super.key});

  @override
  State<MsajiliDashboardView> createState() => _MsajiliDashboardViewState();
}

class _MsajiliDashboardViewState extends State<MsajiliDashboardView> {
  late final MsajiliDashboardController controller;

  /// Mkoa uliobofywa (click) kwa sasa - Matawi yake ndiyo yanayoonekana
  /// chini yake. 'null' = hakuna Mkoa uliofunguliwa.
  int? _expandedRegionId;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<MsajiliDashboardController>()) {
      Get.put(MsajiliDashboardController(Get.find<ApiClient>()));
    }
    controller = Get.find<MsajiliDashboardController>();
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<StorageService>().user;
    final firstName = user?['first_name'] as String? ?? '';
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppShell(
      title: 'Dashibodi ya Msajili',
      child: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
            ]),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(firstName.isEmpty ? 'Karibu' : 'Karibu, $firstName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Muhtasari wa Wanachama uliowasajili wewe mwenyewe.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              _filterBar(context),
              const SizedBox(height: 24),

              LayoutBuilder(builder: (_, c) {
                final count = c.maxWidth > 650 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2.5,
                  children: [
                    _statCard('Jumla', '${controller.total.value}', AppColors.primaryGreen, Icons.groups_outlined),
                    _statCard('Wanawake', '${controller.female.value}', const Color(0xFFD6336C), Icons.female),
                    _statCard('Wanaume', '${controller.male.value}', const Color(0xFF1971C2), Icons.male),
                  ],
                );
              }),
              const SizedBox(height: 24),

              LayoutBuilder(builder: (_, c) {
                return SizedBox(
                  width: c.maxWidth > 700 ? c.maxWidth * 0.6 : c.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: const [
                        Text('Uliowasajili kwa Mkoa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(width: 6),
                        Icon(Icons.touch_app_outlined, size: 15, color: AppColors.textSecondary),
                      ]),
                      const SizedBox(height: 2),
                      const Text('Bofya Mkoa kuona Matawi yake', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      _regionDrilldown(controller.byRegion),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              const Text('Uliowasajili Hivi Karibuni', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: controller.recentMembers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Bado hujasajili mwanachama yeyote.', style: TextStyle(color: AppColors.textSecondary))),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Jina')),
                            DataColumn(label: Text('Simu')),
                            DataColumn(label: Text('Jinsia')),
                            DataColumn(label: Text('Tarehe')),
                          ],
                          rows: controller.recentMembers
                              .map((m) => DataRow(cells: [
                                    DataCell(Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(m.phoneNumber ?? '-')),
                                    DataCell(Text(m.genderLabel ?? '-')),
                                    DataCell(Text(_formatDate(m.createdAt, dateFmt))),
                                  ]))
                              .toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _filterBar(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vichujio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (controller.hasFullAccess)
                    SizedBox(
                      width: 230,
                      child: DropdownButtonFormField<int?>(
                        value: controller.selectedUserId.value,
                        decoration: const InputDecoration(labelText: 'Chagua Msajili', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Mimi Mwenyewe')),
                          ...controller.msajiliUsers.map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.firstName ?? ''} ${u.lastName ?? ''} (${u.username})'.trim()),
                              )),
                        ],
                        onChanged: (v) {
                          controller.selectedUserId.value = v;
                          controller.loadAll();
                        },
                      ),
                    ),
                  SizedBox(
                    width: 200,
                    child: SearchableDropdown(
                      label: 'Mkoa',
                      options: controller.regions,
                      value: controller.filterRegionId.value,
                      onChanged: (v) {
                        controller.filterRegionId.value = v;
                        controller.filterBranchId.value = null;
                        controller.loadAll();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: SearchableDropdown(
                      label: 'Tawi',
                      options: controller.branchesForRegion(controller.filterRegionId.value),
                      value: controller.filterBranchId.value,
                      onChanged: (v) {
                        controller.filterBranchId.value = v;
                        controller.loadAll();
                      },
                    ),
                  ),
                  SizedBox(width: 170, child: _dateField(context, 'Tarehe ya Kuanzia', controller.filterStartDate)),
                  SizedBox(width: 170, child: _dateField(context, 'Tarehe ya Mwisho', controller.filterEndDate)),
                  TextButton.icon(
                    onPressed: controller.resetFilters,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Weka Upya'),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _dateField(BuildContext context, String label, Rxn<DateTime> value) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: value.value == null ? '' : '${value.value!.day.toString().padLeft(2, '0')}/${value.value!.month.toString().padLeft(2, '0')}/${value.value!.year}',
      ),
      decoration: InputDecoration(labelText: label, isDense: true, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 15)),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value.value ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) {
          value.value = picked;
          controller.loadAll();
        }
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ]),
    );
  }

  Widget _regionDrilldown(List<RegionCount> regions) {
    if (regions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
        child: const Text('Hakuna data bado.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      );
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        children: regions.asMap().entries.map((entry) {
          final i = entry.key;
          final region = entry.value;
          final isOpen = _expandedRegionId == region.id;
          final branches = controller.branchesInRegion(region.id);
          return Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expandedRegionId = isOpen ? null : region.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.successBg : (i.isEven ? Theme.of(context).cardColor : AppColors.inputFill),
                    border: i == regions.length - 1 && !isOpen ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(children: [
                    Icon(isOpen ? Icons.expand_more : Icons.chevron_right, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(child: Text(region.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
                    Text('${region.count}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                  ]),
                ),
              ),
              if (isOpen)
                Container(
                  color: AppColors.successBg.withOpacity(0.4),
                  child: Column(
                    children: branches.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              child: Text('Hakuna Tawi lililotambulika kwa Mkoa huu.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                          ]
                        : branches
                            .map((b) => Padding(
                                  padding: const EdgeInsets.only(left: 44, right: 16, top: 9, bottom: 9),
                                  child: Row(children: [
                                    const Icon(Icons.subdirectory_arrow_right, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(b.name, style: const TextStyle(fontSize: 13))),
                                    Text('${b.count}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                                  ]),
                                ))
                            .toList(),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String iso, DateFormat fmt) {
    final d = DateTime.tryParse(iso);
    return d == null ? '' : fmt.format(d);
  }
}
