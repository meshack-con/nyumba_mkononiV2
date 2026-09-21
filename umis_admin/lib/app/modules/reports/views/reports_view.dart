import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../rulers/models/lookup_option.dart';
import '../controllers/reports_controller.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late final ReportsController controller;
  String? _busyKey; // ufunguo wa kitendo kinachoendelea sasa (download/preview)

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ReportsController>()) {
      Get.put(ReportsController(Get.find<ApiClient>()));
    }
    controller = Get.find<ReportsController>();
  }

  Future<void> _download(String key, String path, Map<String, dynamic> query, String filename) async {
    setState(() => _busyKey = '${key}_download');
    try {
      final bytes = await Get.find<ApiClient>().getBytes(path, query: query);
      downloadBytesAsFile(Uint8List.fromList(bytes), filename);
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kutengeneza ripoti.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _preview(String key, String pdfPath, Map<String, dynamic> query) async {
    setState(() => _busyKey = '${key}_preview');
    try {
      final bytes = await Get.find<ApiClient>().getBytes(pdfPath, query: query);
      openPdfBytesInNewTab(bytes);
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kutazama ripoti awali.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ripoti',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ripoti', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Tengeneza na pakua ripoti za mfumo, ukichagua kigezo (mfano: Mkoa, Jinsia, Ngazi ya Elimu).', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            _ReportSection(
              title: 'Muhtasari wa Idadi',
              badge: 'Ukurasa 1 • Hakuna Vigezo',
              description: 'Ripoti ya ukurasa mmoja - idadi za jumla (Jinsia, Kiongozi/Mwanachama, kwa Mkoa, kwa Ngazi ya Elimu). Hakuna kigezo cha kuchagua.',
              icon: Icons.bar_chart_outlined,
              filters: const [],
              busyAction: _busyKey?.startsWith('summary_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('summary', '/api/reports/summary/pdf', {}, 'Ripoti_ya_Muhtasari.pdf'),
              onPreview: () => _preview('summary', '/api/reports/summary/pdf', {}),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti kwa Mkoa/Tawi',
              badge: 'Takwimu Kamili',
              description: 'Muhtasari kamili wa idadi ya Wanachama kwa KILA Mkoa na kwa KILA Tawi (siyo top 8 tu). Hakuna kigezo cha kuchagua.',
              icon: Icons.map_outlined,
              filters: const [],
              busyAction: _busyKey?.startsWith('region_branch_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('region_branch', '/api/reports/region-branch/pdf', {}, 'Ripoti_ya_Mkoa_Tawi.pdf'),
              onDownloadCsv: () => _download('region_branch', '/api/reports/region-branch/csv', {}, 'Ripoti_ya_Mkoa_Tawi.csv'),
              onPreview: () => _preview('region_branch', '/api/reports/region-branch/pdf', {}),
            ),
            const SizedBox(height: 20),
            Obx(() => _ReportSection(
                  title: 'Ripoti ya Wanachama',
                  badge: 'Inachujwa kwa Vigezo',
                  description: 'Orodha ya Wanachama - unaweza kuchuja kwa Jinsia, Mkoa, Tawi, au Hali ya Uanachama.',
                  icon: Icons.people_alt_outlined,
                  filters: [
                    _FilterDropdownSmall(
                      label: 'Jinsia',
                      value: controller.membersGender.value,
                      items: const {'Male': 'Wanaume', 'Female': 'Wanawake'},
                      onChanged: (v) => controller.membersGender.value = v,
                    ),
                    _FilterSearchable(
                      label: 'Mkoa',
                      options: controller.regions,
                      value: controller.membersRegionId.value,
                      onChanged: (v) => controller.membersRegionId.value = v,
                    ),
                    _FilterSearchable(
                      label: 'Tawi',
                      options: controller.branches,
                      value: controller.membersBranchId.value,
                      onChanged: (v) => controller.membersBranchId.value = v,
                    ),
                    _FilterDropdownSmall(
                      label: 'Hali ya Uanachama',
                      value: controller.membersStatus.value,
                      items: const {'MUHITIMU': 'Muhitimu', 'MWANACHUO': 'Mwanachuo', 'DIASPORA': 'Diaspora'},
                      onChanged: (v) => controller.membersStatus.value = v,
                    ),
                  ],
                  onResetFilters: controller.resetMembersFilters,
                  busyAction: _busyKey?.startsWith('members_') == true ? _busyKey!.split('_').last : null,
                  onDownloadPdf: () => _download('members', '/api/reports/members/pdf', controller.membersQuery, 'Ripoti_ya_Wanachama.pdf'),
                  onDownloadCsv: () => _download('members', '/api/reports/members/csv', controller.membersQuery, 'Ripoti_ya_Wanachama.csv'),
                  onPreview: () => _preview('members', '/api/reports/members/pdf', controller.membersQuery),
                )),
            const SizedBox(height: 20),
            Obx(() => _ReportSection(
                  title: 'Ripoti ya Uongozi',
                  badge: 'Viongozi & Nafasi',
                  description: 'Orodha ya nafasi za uongozi zilizothibitishwa - unaweza kuchuja kwa Nafasi/Cheo, au Mkoa.',
                  icon: Icons.emoji_events_outlined,
                  filters: [
                    _FilterSearchable(
                      label: 'Nafasi/Cheo',
                      options: controller.leaderships,
                      value: controller.leadershipFilterId.value,
                      onChanged: (v) => controller.leadershipFilterId.value = v,
                    ),
                    _FilterSearchable(
                      label: 'Mkoa',
                      options: controller.regions,
                      value: controller.leadershipRegionId.value,
                      onChanged: (v) => controller.leadershipRegionId.value = v,
                    ),
                  ],
                  onResetFilters: controller.resetLeadershipFilters,
                  busyAction: _busyKey?.startsWith('leadership_') == true ? _busyKey!.split('_').last : null,
                  onDownloadPdf: () => _download('leadership', '/api/reports/leadership/pdf', controller.leadershipQuery, 'Ripoti_ya_Uongozi.pdf'),
                  onDownloadCsv: () => _download('leadership', '/api/reports/leadership/csv', controller.leadershipQuery, 'Ripoti_ya_Uongozi.csv'),
                  onPreview: () => _preview('leadership', '/api/reports/leadership/pdf', controller.leadershipQuery),
                )),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Elimu',
              badge: 'Inachujwa kwa Vigezo',
              description: 'Orodha ya taarifa za elimu za Wanachama - unaweza kuchuja kwa Ngazi ya Elimu au Programu/Kozi (andika jina sahihi).',
              icon: Icons.school_outlined,
              filters: [
                _FilterTextSmall(label: 'Ngazi ya Elimu (mfano: Shahada)', controller: controller.educationLevelCtrl),
                _FilterTextSmall(label: 'Programu/Kozi (mfano: Sayansi ya Kompyuta)', controller: controller.educationProgramCtrl),
              ],
              onResetFilters: controller.resetEducationFilters,
              busyAction: _busyKey?.startsWith('education_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('education', '/api/reports/education/pdf', controller.educationQuery, 'Ripoti_ya_Elimu.pdf'),
              onDownloadCsv: () => _download('education', '/api/reports/education/csv', controller.educationQuery, 'Ripoti_ya_Elimu.csv'),
              onPreview: () => _preview('education', '/api/reports/education/pdf', controller.educationQuery),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Ajira',
              badge: 'Inachujwa kwa Vigezo',
              description: 'Orodha ya uzoefu wa kazi wa Wanachama - unaweza kuchuja kwa Aina ya Ajira (andika jina sahihi).',
              icon: Icons.work_outline,
              filters: [
                _FilterTextSmall(label: 'Aina ya Ajira', controller: controller.employmentTypeCtrl),
              ],
              onResetFilters: controller.resetEmploymentFilters,
              busyAction: _busyKey?.startsWith('employment_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('employment', '/api/reports/employment/pdf', controller.employmentQuery, 'Ripoti_ya_Ajira.pdf'),
              onDownloadCsv: () => _download('employment', '/api/reports/employment/csv', controller.employmentQuery, 'Ripoti_ya_Ajira.csv'),
              onPreview: () => _preview('employment', '/api/reports/employment/pdf', controller.employmentQuery),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Mafunzo',
              badge: 'Inachujwa kwa Vigezo',
              description: 'Orodha ya mafunzo waliyohudhuria Wanachama - unaweza kuchuja kwa Aina ya Mafunzo au Mahali.',
              icon: Icons.military_tech_outlined,
              filters: [
                _FilterTextSmall(label: 'Aina ya Mafunzo', controller: controller.trainingTypeCtrl),
                _FilterTextSmall(label: 'Mahali', controller: controller.trainingLocationCtrl),
              ],
              onResetFilters: controller.resetTrainingFilters,
              busyAction: _busyKey?.startsWith('training_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('training', '/api/reports/training/pdf', controller.trainingQuery, 'Ripoti_ya_Mafunzo.pdf'),
              onDownloadCsv: () => _download('training', '/api/reports/training/csv', controller.trainingQuery, 'Ripoti_ya_Mafunzo.csv'),
              onPreview: () => _preview('training', '/api/reports/training/pdf', controller.trainingQuery),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Kazi/Utaalamu',
              badge: 'Hakuna Vigezo',
              description: 'Idadi ya Wanachama kwa kila Kazi/Utaalamu na Aina ya Kazi. Hakuna kigezo cha kuchagua.',
              icon: Icons.badge_outlined,
              filters: const [],
              busyAction: _busyKey?.startsWith('occupation_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('occupation', '/api/reports/occupation/pdf', {}, 'Ripoti_ya_Kazi.pdf'),
              onPreview: () => _preview('occupation', '/api/reports/occupation/pdf', {}),
            ),
            const SizedBox(height: 20),
            Obx(() => _ReportSection(
                  title: 'Ripoti ya Wadau',
                  badge: 'Inachujwa kwa Vigezo',
                  description: 'Orodha ya Wadau (Binafsi/Taasisi) - unaweza kuchuja kwa aina.',
                  icon: Icons.handshake_outlined,
                  filters: [
                    _FilterDropdownSmall(
                      label: 'Aina',
                      value: controller.stakeholderKind.value,
                      items: const {'BINAFSI': 'Binafsi', 'TAASISI': 'Taasisi'},
                      onChanged: (v) => controller.stakeholderKind.value = v,
                    ),
                  ],
                  onResetFilters: controller.resetStakeholderFilters,
                  busyAction: _busyKey?.startsWith('stakeholders_') == true ? _busyKey!.split('_').last : null,
                  onDownloadPdf: () => _download('stakeholders', '/api/reports/stakeholders/pdf', controller.stakeholderQuery, 'Ripoti_ya_Wadau.pdf'),
                  onDownloadCsv: () => _download('stakeholders', '/api/reports/stakeholders/csv', controller.stakeholderQuery, 'Ripoti_ya_Wadau.csv'),
                  onPreview: () => _preview('stakeholders', '/api/reports/stakeholders/pdf', controller.stakeholderQuery),
                )),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Akaunti za Kuingia',
              badge: 'Hakuna Vigezo',
              description: 'Wanachama wenye akaunti ya Mobile App dhidi ya wasio nayo. Hakuna kigezo cha kuchagua.',
              icon: Icons.key_outlined,
              filters: const [],
              busyAction: _busyKey?.startsWith('accounts_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('accounts', '/api/reports/accounts/pdf', {}, 'Ripoti_ya_Akaunti.pdf'),
              onDownloadCsv: () => _download('accounts', '/api/reports/accounts/csv', {}, 'Ripoti_ya_Akaunti.csv'),
              onPreview: () => _preview('accounts', '/api/reports/accounts/pdf', {}),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final canDownload = controller.registrationPeriodQuery != null;
              return _ReportSection(
                title: 'Ripoti ya Usajili kwa Kipindi',
                badge: 'Kipindi cha Tarehe',
                description: 'Wanachama waliojisajili KATI ya tarehe mbili - chagua Tarehe ya Kuanzia na Tarehe ya Mwisho kabla ya kupakua.',
                icon: Icons.date_range_outlined,
                filters: [
                  _FilterDateSmall(label: 'Tarehe ya Kuanzia', value: controller.registrationStart.value, onChanged: (d) => controller.registrationStart.value = d),
                  _FilterDateSmall(label: 'Tarehe ya Mwisho', value: controller.registrationEnd.value, onChanged: (d) => controller.registrationEnd.value = d),
                ],
                onResetFilters: controller.resetRegistrationPeriodFilters,
                busyAction: _busyKey?.startsWith('registration_') == true ? _busyKey!.split('_').last : null,
                onDownloadPdf: !canDownload
                    ? () => Get.snackbar('Chagua Tarehe', 'Chagua Tarehe ya Kuanzia na ya Mwisho kwanza.', snackPosition: SnackPosition.BOTTOM)
                    : () => _download('registration', '/api/reports/registration-period/pdf', controller.registrationPeriodQuery!, 'Ripoti_ya_Usajili.pdf'),
                onDownloadCsv: !canDownload
                    ? () => Get.snackbar('Chagua Tarehe', 'Chagua Tarehe ya Kuanzia na ya Mwisho kwanza.', snackPosition: SnackPosition.BOTTOM)
                    : () => _download('registration', '/api/reports/registration-period/csv', controller.registrationPeriodQuery!, 'Ripoti_ya_Usajili.csv'),
                onPreview: !canDownload
                    ? null
                    : () => _preview('registration', '/api/reports/registration-period/pdf', controller.registrationPeriodQuery!),
              );
            }),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Taarifa Zisizokamilika',
              badge: 'Hakuna Vigezo',
              description: 'Wanachama wasio na Simu, Email, Picha, au Mkoa - kwa ufuatiliaji wa kukamilisha data. Hakuna kigezo cha kuchagua.',
              icon: Icons.warning_amber_outlined,
              filters: const [],
              busyAction: _busyKey?.startsWith('incomplete_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('incomplete', '/api/reports/incomplete-profile/pdf', {}, 'Ripoti_ya_Taarifa_Zisizokamilika.pdf'),
              onDownloadCsv: () => _download('incomplete', '/api/reports/incomplete-profile/csv', {}, 'Ripoti_ya_Taarifa_Zisizokamilika.csv'),
              onPreview: () => _preview('incomplete', '/api/reports/incomplete-profile/pdf', {}),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: 'Ripoti ya Uthibitisho Unaosubiri',
              badge: 'Hakuna Vigezo',
              description: 'Nafasi za uongozi walizojiwekea wenyewe Wanachama (self-service) ambazo bado hazijathibitishwa na Admin. Hakuna kigezo cha kuchagua.',
              icon: Icons.hourglass_top_outlined,
              filters: const [],
              busyAction: _busyKey?.startsWith('pending_verification_') == true ? _busyKey!.split('_').last : null,
              onDownloadPdf: () => _download('pending_verification', '/api/reports/pending-verification/pdf', {}, 'Ripoti_ya_Uthibitisho_Unaosubiri.pdf'),
              onPreview: () => _preview('pending_verification', '/api/reports/pending-verification/pdf', {}),
            ),
            const SizedBox(height: 20),
            // MUHIMU: kadi ya "uhakika" mwishoni - kama mockup - inatoa
            // uhakikisho wa jumla kwa Admin (siyo maalum kwa ripoti moja).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Uhakika na Usalama', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primaryGreen)),
                      SizedBox(height: 4),
                      Text('Ripoti zote ni sahihi, salama na zinapatikana kila wakati. Hakikisha unachagua kigezo sahihi kabla ya kupakua.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            const _ReportsFooter(),
          ],
        ),
      ),
    );
  }
}

class _ReportsFooter extends StatelessWidget {
  const _ReportsFooter();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 6,
        children: [
          Text('© $year Mfumo wa Wanachama. Haki zote zimehifadhiwa.', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.circle, size: 8, color: AppColors.success),
              SizedBox(width: 6),
              Text('Mfumo Uko Hewani', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              SizedBox(width: 14),
              Text('Toleo 1.0', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final String? badge;
  final String description;
  final IconData icon;
  final List<Widget> filters;
  final VoidCallback? onResetFilters;
  final String? busyAction; // 'download' | 'preview' | null
  final VoidCallback onDownloadPdf;
  final VoidCallback? onDownloadCsv;
  final VoidCallback? onPreview;

  const _ReportSection({
    required this.title,
    this.badge,
    required this.description,
    required this.icon,
    required this.filters,
    this.onResetFilters,
    this.busyAction,
    required this.onDownloadPdf,
    this.onDownloadCsv,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Stack(
        children: [
          // MUHIMU: "illustration" ya mapambo upande wa kulia (icon kubwa
          // laini) - kama mockup - inaonekana TU kwenye skrini pana (siyo
          // simu/tablet nyembamba, ili isibane maudhui muhimu).
          if (MediaQuery.of(context).size.width > 700)
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 140,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.successBg.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Icon(icon, size: 64, color: AppColors.primaryGreen.withOpacity(0.35)),
                ),
              ),
            ),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.06), border: const Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    if (badge != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(badge!, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5)),
                if (filters.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(spacing: 14, runSpacing: 14, children: filters),
                  if (onResetFilters != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onResetFilters,
                        icon: const Icon(Icons.refresh, size: 15),
                        label: const Text('Weka Upya Vichujio', style: TextStyle(fontSize: 12.5)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary, padding: EdgeInsets.zero),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                        onPressed: busyAction != null ? null : onDownloadPdf,
                        icon: busyAction == 'download'
                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text('Pakua PDF'),
                      ),
                    ),
                    if (onDownloadCsv != null)
                      SizedBox(
                        width: 160,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryGreen, side: const BorderSide(color: AppColors.primaryGreen)),
                          onPressed: busyAction != null ? null : onDownloadCsv,
                          icon: busyAction == 'download'
                              ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.table_chart_outlined, size: 16),
                          label: const Text('Pakua CSV'),
                        ),
                      ),
                    if (onPreview != null)
                      SizedBox(
                        width: 150,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border)),
                          onPressed: busyAction != null ? null : onPreview,
                          icon: busyAction == 'preview'
                              ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Tazama Awali'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
  }
}

class _FilterDropdownSmall extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdownSmall({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          const DropdownMenuItem(value: null, child: Text('Wote')),
          ...items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterSearchable extends StatelessWidget {
  final String label;
  final List<LookupOption> options;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _FilterSearchable({required this.label, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SearchableDropdown(label: label, options: options, value: value, onChanged: onChanged),
    );
  }
}

class _FilterTextSmall extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _FilterTextSmall({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}

class _FilterDateSmall extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _FilterDateSmall({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value == null ? '' : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'),
        decoration: InputDecoration(labelText: label, isDense: true, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16)),
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }
}
