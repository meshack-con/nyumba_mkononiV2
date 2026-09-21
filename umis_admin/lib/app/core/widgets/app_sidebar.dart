import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_badges_controller.dart';
import '../controllers/sidebar_state_controller.dart';
import '../routes/app_routes.dart';
import '../storage/storage_service.dart';
import '../theme/app_colors.dart';

class _SidebarLeaf {
  final String label;
  final IconData icon;
  final String? route; // null = bado haijajengwa (coming soon)

  const _SidebarLeaf(this.label, this.icon, [this.route]);
}

class _SidebarGroup {
  final String label;
  final IconData icon;
  final List<_SidebarLeaf> children;

  const _SidebarGroup(this.label, this.icon, this.children);
}

final List<Object> _menu = [
  const _SidebarLeaf('sb_dashboard', Icons.dashboard_outlined, AppRoutes.dashboard),
  const _SidebarGroup('sb_registration_group', Icons.how_to_reg_outlined, [
    _SidebarLeaf('sb_rulers', Icons.people_outline, AppRoutes.rulerList),
    _SidebarLeaf('sb_leadership_verification', Icons.verified_outlined, AppRoutes.leadershipVerification),
    _SidebarLeaf('sb_wadau', Icons.handshake_outlined, AppRoutes.wadau),
  ]),
  const _SidebarGroup('sb_messages_group', Icons.mail_outline, [
    _SidebarLeaf('sb_admin_messages', Icons.campaign_outlined, AppRoutes.adminMessages),
    _SidebarLeaf('sb_conversations', Icons.chat_bubble_outline, AppRoutes.conversations),
    _SidebarLeaf('sb_admin_notifications', Icons.notifications_none_outlined, AppRoutes.adminNotifications),
  ]),
  const _SidebarGroup('sb_forum', Icons.forum_outlined, [
    _SidebarLeaf('sb_forum_content', Icons.dynamic_feed_outlined, AppRoutes.forumContent),
    _SidebarLeaf('sb_forum_categories', Icons.category_outlined, AppRoutes.forumCategories),
    _SidebarLeaf('sb_forum_moderation', Icons.report_gmailerrorred_outlined, AppRoutes.forumModeration),
  ]),
  const _SidebarGroup('sb_reports_group', Icons.bar_chart_outlined, [
    _SidebarLeaf('sb_reports', Icons.bar_chart_outlined, AppRoutes.reports),
    _SidebarLeaf('sb_msajili_reports', Icons.dashboard_outlined, AppRoutes.msajiliDashboard),
  ]),
  const _SidebarGroup('sb_settings_group', Icons.settings_outlined, [
    _SidebarLeaf('sb_settings_hub', Icons.tune_outlined, AppRoutes.settingsHub),
    _SidebarLeaf('sb_audit_trail', Icons.fact_check_outlined, AppRoutes.auditTrail),
    _SidebarLeaf('sb_login_history', Icons.history, AppRoutes.loginHistory),
    _SidebarLeaf('sb_users', Icons.admin_panel_settings_outlined, AppRoutes.users),
  ]),
];

/// Kwa mtumiaji wa role "MSAJILI" TU (hana ADMIN/USER pia) - menyu
/// inapunguzwa kuonyesha TU vitu anavyoruhusiwa navyo na Backend
/// (kusajili/kuona Wanachama) - kuepuka kumwonyesha vitu atakavyobofya
/// na kupata "Huna ruhusa" (403). "Dashboard" HAIONEKANI hapa kwa
/// makusudi - Msajili hana ruhusa ya kuona takwimu za jumla za mfumo.
final List<Object> _msajiliMenu = [
  const _SidebarLeaf('sb_msajili_dashboard', Icons.dashboard_outlined, AppRoutes.msajiliDashboard),
  const _SidebarLeaf('sb_rulers', Icons.people_outline, AppRoutes.rulerList),
];

class AppSidebar extends StatelessWidget {
  final bool collapsed;
  final bool mobile;
  const AppSidebar({super.key, this.collapsed = false, this.mobile = false});

  void _handleLeafTap(_SidebarLeaf leaf) {
    if (mobile) Get.back(); // funga Drawer kwanza
    if (leaf.route != null) {
      Get.offAllNamed(leaf.route!);
    } else {
      Get.snackbar(
        'Inakuja hivi karibuni',
        '"${leaf.label.tr}" bado inajengwa.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.sidebarGreen,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidebarState = Get.find<SidebarStateController>();
    final currentRoute = Get.currentRoute;
    final showText = !collapsed || mobile;
    final menu = Get.find<StorageService>().isMsajiliOnly ? _msajiliMenu : _menu;

    return Material(
      color: AppColors.sidebarGreen,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset('assets/images/logo.png', width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  if (showText) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'UMIS CORE\nADMIN PANEL',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.25),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: Obx(
                () {
                  // MUHIMU: soma Rx MOJA angalau bila masharti (hapa chini)
                  // KABLA ya kujenga ListView - kama menyu ya sasa (mfano
                  // '_msajiliMenu') haina "_SidebarGroup" yoyote, hakuna
                  // sehemu nyingine ndani ya Obx hii inayosoma
                  // 'sidebarState.expandedGroups' - na Obx isiyosoma Rx
                  // YOYOTE inatupa hitilafu ya "improper use of GetX".
                  final _ = sidebarState.expandedGroups.length;
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    children: menu.map((item) {
                    if (item is _SidebarLeaf) {
                      final active = item.route != null && item.route == currentRoute;
                      return _LeafTile(leaf: item, active: active, showText: showText, collapsed: collapsed, onTap: () => _handleLeafTap(item));
                    }
                    final group = item as _SidebarGroup;
                    // Kundi linaonekana "wazi" kama: (a) mtumiaji amelifungua mwenyewe, AU
                    // (b) ukurasa wa sasa uko ndani ya kundi hili (auto-open) - hivyo
                    // haliwezi "kujifunga" lenyewe unapohama kati ya kurasa za kundi lilelile.
                    final containsCurrentRoute = group.children.any((c) => c.route == currentRoute);
                    final isOpen = sidebarState.expandedGroups.contains(group.label) || containsCurrentRoute;

                    if (collapsed && !mobile) {
                      return Column(
                        children: [
                          Tooltip(message: group.label.tr, child: Icon(group.icon, color: Colors.white54, size: 18)),
                          const SizedBox(height: 4),
                          ...group.children.map((leaf) => _LeafTile(
                                leaf: leaf,
                                active: leaf.route != null && leaf.route == currentRoute,
                                showText: false,
                                collapsed: true,
                                onTap: () => _handleLeafTap(leaf),
                              )),
                          const SizedBox(height: 6),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => sidebarState.toggle(group.label),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                Icon(group.icon, color: Colors.white70, size: 19),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(group.label.tr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ),
                                Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: Colors.white54, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (isOpen)
                          ...group.children.map(
                            (leaf) => Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: _LeafTile(
                                leaf: leaf,
                                active: leaf.route != null && leaf.route == currentRoute,
                                showText: true,
                                collapsed: false,
                                onTap: () => _handleLeafTap(leaf),
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                  );
                },
              ),
            ),
            if (showText)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('UMIS Core v1.0 • FastAPI', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeafTile extends StatelessWidget {
  final _SidebarLeaf leaf;
  final bool active;
  final bool showText;
  final bool collapsed;
  final VoidCallback onTap;

  const _LeafTile({
    required this.leaf,
    required this.active,
    required this.showText,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? leaf.label.tr : '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accentYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(leaf.icon, color: active ? AppColors.activeNavText : Colors.white70, size: 19),
              if (showText) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    leaf.label.tr,
                    style: TextStyle(
                      color: active ? AppColors.activeNavText : Colors.white,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // MUHIMU: badge hii inaonekana kwenye MAENEO KADHAA (siyo
              // 'Mazungumzo' tu) - kila mahali penye 'data mpya kutoka kwa
              // Wanachama' inayohitaji uangalizi wa Admin - imesasika kila
              // sekunde 15 (angalia AdminBadgesController).
              Obx(() {
                final badges = Get.find<AdminBadgesController>();
                // MUHIMU: soma '.value' ZOTE bila masharti KWANZA (kabla
                // ya 'switch') - hii ndiyo inayohakikisha Obx INAONA
                // usomaji wa 'reactive' hata kwa 'leaf' zisizolingana na
                // route yoyote (mfano 'Mipangilio') - bila hii, tawi la
                // 'default' halisomi '.value' yoyote, na GetX inatupa
                // "improper use of GetX" (kama ilivyoripotiwa).
                final unreadMessages = badges.unreadMessages.value;
                final newMembers7d = badges.newMembers7d.value;
                final pendingLeadership = badges.pendingLeadership.value;
                final pendingReports = badges.pendingReports.value;
                final pendingOpportunities = badges.pendingOpportunities.value;
                final count = switch (leaf.route) {
                  AppRoutes.conversations => unreadMessages,
                  AppRoutes.rulerList => newMembers7d,
                  AppRoutes.leadershipVerification => pendingLeadership,
                  AppRoutes.forumModeration => pendingReports,
                  AppRoutes.forumContent => pendingOpportunities,
                  _ => 0,
                };
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                  child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
