import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/ruler_avatar.dart';
import '../../forum_categories/forum_categories_service.dart';
import '../../forum_categories/models/forum_category_model.dart';
import '../../rulers/models/lookup_option.dart';
import '../controllers/forum_content_controller.dart';
import '../forum_content_service.dart';

class ForumContentView extends GetView<ForumContentController> {
  const ForumContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Forum - Mada na Fursa',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Forum - Mada na Fursa',
            subtitle: 'Vinjari, tafuta, na simamia content YOTE ya Forum (siyo tu iliyoripotiwa).',
          ),
          const SizedBox(height: 14),
          Obx(
            () => Row(
              children: [
                ChoiceChip(
                  label: const Text('💬 Mada (Topics)'),
                  selected: controller.tabIndex.value == 0,
                  onSelected: (_) => controller.switchTab(0),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text('💼 Fursa (Opportunities)${controller.pendingCount > 0 ? ' • ${controller.pendingCount} zinasubiri' : ''}'),
                  selected: controller.tabIndex.value == 1,
                  selectedColor: controller.pendingCount > 0 ? AppColors.accentYellow.withOpacity(0.4) : null,
                  onSelected: (_) => controller.switchTab(1),
                ),
                const Spacer(),
                if (controller.tabIndex.value == 1)
                  ElevatedButton.icon(
                    onPressed: () => Get.dialog(const _CreateOpportunityDialog()),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ongeza Fursa'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 340,
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 20), hintText: 'Tafuta kwa jina...', isDense: true),
              onSubmitted: (v) {
                controller.searchText.value = v;
                controller.loadAll();
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                    if (controller.tabIndex.value == 0) ...[
                      _TopRatedCard(),
                      const SizedBox(height: 16),
                    ],
                    controller.tabIndex.value == 0 ? const _TopicsTable() : const _OpportunitiesTable(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TopRatedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForumContentController>();
    final topRated = controller.topRatedTopics;
    if (topRated.isEmpty) return const SizedBox();
    return Card(
      color: AppColors.successBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⭐ Mada Zenye Rating ya Juu Zaidi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            ...topRated.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      Text('${t.averageRating.toStringAsFixed(1)} ⭐ (${t.ratingCount})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TopicsTable extends StatelessWidget {
  const _TopicsTable();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForumContentController>();
    final dateFmt = DateFormat('dd/MM/yyyy');
    if (controller.topics.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Text('Hakuna mada.', style: TextStyle(color: AppColors.textSecondary)));
    }
    return DataTableCard(
      columns: const [
        DataColumn(label: Text('Jina la Mada')),
        DataColumn(label: Text('Mwandishi')),
        DataColumn(label: Text('Mapendekezo/Maoni')),
        DataColumn(label: Text('Ukadiriaji')),
        DataColumn(label: Text('Tarehe')),
        DataColumn(label: Text('Hali')),
        DataColumn(label: Text('Vitendo')),
      ],
      rows: controller.topics.map((t) {
        return DataRow(cells: [
          DataCell(SizedBox(width: 220, child: Text(t.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))),
          DataCell(Row(children: [
            RulerAvatar(rulerId: t.rulerId, name: t.authorName ?? '-', radius: 13),
            const SizedBox(width: 8),
            Text(t.authorName ?? '-'),
          ])),
          DataCell(Text('${t.likeCount} / ${t.commentCount}')),
          DataCell(Text(t.ratingCount > 0 ? '${t.averageRating.toStringAsFixed(1)} ⭐ (${t.ratingCount})' : '-')),
          DataCell(Text(dateFmt.format(t.createdAt))),
          DataCell(Text(t.isBlocked ? 'Amezuiwa' : 'Hai', style: TextStyle(color: t.isBlocked ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w600))),
          DataCell(Row(children: [
            TextButton(onPressed: () => controller.toggleTopicBlock(t), child: Text(t.isBlocked ? 'Fungua' : 'Zuia')),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, 'mada', t.title, () => controller.deleteTopic(t.id)),
            ),
          ])),
        ]);
      }).toList(),
    );
  }
}

class _OpportunitiesTable extends StatelessWidget {
  const _OpportunitiesTable();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForumContentController>();
    final dateFmt = DateFormat('dd/MM/yyyy');
    if (controller.opportunities.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Text('Hakuna fursa.', style: TextStyle(color: AppColors.textSecondary)));
    }
    return DataTableCard(
      columns: const [
        DataColumn(label: Text('Jina la Fursa')),
        DataColumn(label: Text('Mwandishi')),
        DataColumn(label: Text('Mahali')),
        DataColumn(label: Text('Mwisho wa Muda')),
        DataColumn(label: Text('Waliopendezwa')),
        DataColumn(label: Text('Uthibitisho')),
        DataColumn(label: Text('Hali')),
        DataColumn(label: Text('Vitendo')),
      ],
      rows: controller.opportunities.map((o) {
        return DataRow(cells: [
          DataCell(SizedBox(width: 220, child: Text(o.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))),
          DataCell(Row(children: [
            RulerAvatar(rulerId: o.rulerId, name: o.authorName ?? 'Admin/UVCCM', radius: 13),
            const SizedBox(width: 8),
            Text(o.authorName ?? 'Admin/UVCCM'),
          ])),
          DataCell(Text(o.location ?? '-')),
          DataCell(Text(o.deadline != null ? dateFmt.format(o.deadline!) : '-')),
          DataCell(Text('${o.interestedCount}')),
          DataCell(
            o.isApproved
                ? const Text('Imethibitishwa', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12.5))
                : const Text('Inasubiri', style: TextStyle(color: AppColors.accentYellow, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
          DataCell(Text(o.isBlocked ? 'Amezuiwa' : 'Hai', style: TextStyle(color: o.isBlocked ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w600))),
          DataCell(Row(children: [
            if (!o.isApproved)
              TextButton(
                onPressed: () => controller.approveOpportunity(o.id),
                child: const Text('Idhinisha', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
              ),
            IconButton(
              icon: const Icon(Icons.insights_outlined, size: 18, color: AppColors.info),
              tooltip: 'Takwimu za Arifa',
              onPressed: () => Get.dialog(_NotificationStatsDialog(opportunityId: o.id, title: o.title)),
            ),
            TextButton(onPressed: () => controller.toggleOpportunityBlock(o), child: Text(o.isBlocked ? 'Fungua' : 'Zuia')),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, 'fursa', o.title, () => controller.deleteOpportunity(o.id)),
            ),
          ])),
        ]);
      }).toList(),
    );
  }
}

class _NotificationStatsDialog extends StatefulWidget {
  final int opportunityId;
  final String title;
  const _NotificationStatsDialog({required this.opportunityId, required this.title});

  @override
  State<_NotificationStatsDialog> createState() => _NotificationStatsDialogState();
}

class _NotificationStatsDialogState extends State<_NotificationStatsDialog> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await Get.find<ForumContentController>().getNotificationStats(widget.opportunityId);
    if (mounted) setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final service = ForumContentService(Get.find<ApiClient>());
      final result = await service.resendNotifications(widget.opportunityId);
      Get.snackbar('Imefanikiwa', 'Arifa zimetumwa kwa ${result['sent_to']} wanachama.', snackPosition: SnackPosition.BOTTOM);
      await _load();
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kutuma arifa.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Takwimu za Arifa - ${widget.title}'),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : _stats == null
              ? const Text('Imeshindikana kupakia takwimu.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wamepokea Arifa: ${_stats!['total_notified']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Wamefungua/Kusoma: ${_stats!['total_read']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                    if ((_stats!['total_notified'] as int) == 0) ...[
                      const SizedBox(height: 10),
                      const Text('Hakuna aliyepokea arifa (Fursa hii haina Kazi/Utaalamu iliyotagiwa, au hakuna aliyechagua Kazi hiyo WAKATI Fursa hii ilipochapishwa - arifa zinahesabiwa MARA MOJA TU wakati huo).', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isResending ? null : _resend,
                        icon: _isResending
                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.replay, size: 16),
                        label: const Text('Tuma Arifa Tena (kwa data ya sasa)'),
                      ),
                    ),
                  ],
                ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Funga'))],
    );
  }
}

void _confirmDelete(BuildContext context, String kind, String name, VoidCallback onConfirm) {
  Get.dialog(
    AlertDialog(
      title: Text('Futa ${kind == 'mada' ? 'Mada' : 'Fursa'}'),
      content: Text('Una uhakika unataka kufuta "$name"?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () {
            Get.back();
            onConfirm();
          },
          child: const Text('Futa'),
        ),
      ],
    ),
  );
}

class _CreateOpportunityDialog extends StatefulWidget {
  const _CreateOpportunityDialog();

  @override
  State<_CreateOpportunityDialog> createState() => _CreateOpportunityDialogState();
}

class _CreateOpportunityDialogState extends State<_CreateOpportunityDialog> {
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final requirementsCtrl = TextEditingController();
  final contactLinkCtrl = TextEditingController();
  DateTime? deadline;
  int? categoryId;
  final Set<int> selectedOccupationIds = {};

  bool _isLoadingLookups = true;
  bool _isSaving = false;
  String? _lookupError;
  List<ForumCategoryModel> _categories = [];
  List<LookupOption> _occupations = [];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _lookupError = null;
    });
    try {
      final categoriesService = ForumCategoriesService(Get.find<ApiClient>());
      _categories = await categoriesService.list(kind: 'OPPORTUNITY');
      final occData = await Get.find<ApiClient>().get('/api/occupations/', query: {'limit': 500});
      _occupations = (occData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _lookupError = 'Imeshindikana kupakia Category/Occupations: $e';
    } finally {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _submit() async {
    if (titleCtrl.text.trim().isEmpty || categoryId == null) {
      Get.snackbar('Kosa', 'Jaza Jina la Fursa na uchague Category.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final service = ForumContentService(Get.find<ApiClient>());
      await service.createOpportunityAsAdmin(
        title: titleCtrl.text.trim(),
        description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
        location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
        deadline: deadline,
        requirements: requirementsCtrl.text.trim().isEmpty ? null : requirementsCtrl.text.trim(),
        contactLink: contactLinkCtrl.text.trim().isEmpty ? null : contactLinkCtrl.text.trim(),
        categoryId: categoryId!,
        occupationIds: selectedOccupationIds.toList(),
      );
      Get.back();
      Get.snackbar('Imefanikiwa', 'Fursa imetangazwa - iko "live" papo hapo.', snackPosition: SnackPosition.BOTTOM);
      Get.find<ForumContentController>().loadAll();
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kutangaza Fursa.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoadingLookups
              ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
              : _lookupError != null
                  ? SizedBox(
                      height: 160,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_lookupError!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadLookups, child: const Text('Jaribu Tena')),
                      ]),
                    )
                  : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ongeza Fursa (Admin)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Fursa hii itaenda "live" MOJA KWA MOJA (haihitaji uthibitisho).', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 18),
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Jina la Fursa')),
                      const SizedBox(height: 12),
                      TextField(controller: descriptionCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Maelezo')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: categoryId,
                        decoration: InputDecoration(
                          labelText: 'Kategoria',
                          helperText: _categories.isEmpty ? 'Hakuna Category ya aina "Fursa" bado - nenda Forum > Categories kuunda moja kwanza.' : null,
                          helperMaxLines: 2,
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: _categories.isEmpty ? null : (v) => setState(() => categoryId = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Mahali')),
                      const SizedBox(height: 12),
                      TextField(controller: requirementsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Sifa Zinazohitajika')),
                      const SizedBox(height: 12),
                      TextField(controller: contactLinkCtrl, decoration: const InputDecoration(labelText: 'Mawasiliano/Link ya Kuomba')),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                          if (picked != null) setState(() => deadline = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Mwisho wa Muda', suffixIcon: Icon(Icons.calendar_today_outlined, size: 16)),
                          child: Text(deadline == null ? '-' : '${deadline!.day}/${deadline!.month}/${deadline!.year}'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Kazi/Utaalamu Inayohusika (hiari - kwa arifa)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _occupations.map((o) {
                          final selected = selectedOccupationIds.contains(o.id);
                          return FilterChip(
                            label: Text(o.name, style: const TextStyle(fontSize: 12.5)),
                            selected: selected,
                            onSelected: (v) => setState(() => v ? selectedOccupationIds.add(o.id) : selectedOccupationIds.remove(o.id)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            child: _isSaving
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Tangaza Fursa'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
                      ]),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
