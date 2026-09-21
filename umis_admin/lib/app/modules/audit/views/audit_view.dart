import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/audit_controller.dart';
import '../models/audit_log_model.dart';

class AuditView extends GetView<AuditController> {
  const AuditView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return AppShell(
      title: 'Audit Trail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Audit Trail',
            subtitle: 'Rekodi ya matukio muhimu ndani ya mfumo - nani alifanya nini, lini (read-only).',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 340,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: 'Mtumiaji, aina ya kitu, au maelezo...',
                    isDense: true,
                  ),
                  onChanged: (v) => controller.searchText.value = v,
                ),
              ),
              Obx(
                () => DropdownButton<String?>(
                  value: controller.actionFilter.value,
                  hint: const Text('Aina ya Tukio: Wote'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Matukio Yote')),
                    DropdownMenuItem(value: 'CREATE', child: Text('Kuongezwa (CREATE)')),
                    DropdownMenuItem(value: 'UPDATE', child: Text('Kusasishwa (UPDATE)')),
                    DropdownMenuItem(value: 'DELETE', child: Text('Kufutwa (DELETE)')),
                  ],
                  onChanged: controller.setActionFilter,
                ),
              ),
            ],
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
                    ElevatedButton(onPressed: controller.loadLogs, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              final list = controller.filteredLogs;
              if (list.isEmpty) {
                return const Center(child: Text('Hakuna rekodi bado.', style: TextStyle(color: AppColors.textSecondary)));
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Tukio')),
                    DataColumn(label: Text('Aina ya Kitu')),
                    DataColumn(label: Text('Maelezo')),
                    DataColumn(label: Text('Mtumiaji')),
                    DataColumn(label: Text('Tarehe')),
                  ],
                  rows: list.map((l) {
                    return DataRow(cells: [
                      DataCell(_ActionBadge(action: l.action)),
                      DataCell(Text(l.entityType)),
                      DataCell(SizedBox(width: 320, child: Text(l.description ?? '-', overflow: TextOverflow.ellipsis))),
                      DataCell(Text(l.username ?? '-')),
                      DataCell(Text(dateFmt.format(l.createdAt))),
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
}

class _ActionBadge extends StatelessWidget {
  final String action;
  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (action) {
      case 'CREATE':
        color = AppColors.success;
        break;
      case 'DELETE':
        color = AppColors.danger;
        break;
      case 'UPDATE':
      default:
        color = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(action, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
