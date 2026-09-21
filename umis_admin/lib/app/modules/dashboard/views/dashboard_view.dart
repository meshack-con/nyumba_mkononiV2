import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Dashboard',
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
                const SizedBox(height: 12),
                ElevatedButton(onPressed: controller.loadSummary, child: const Text('Jaribu tena')),
              ],
            ),
          );
        }

        final s = controller.summary.value!;
        return RefreshIndicator(
          onRefresh: controller.loadSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Karibu kwenye UMIS Core', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text(
                  'Muhtasari wa wanachama, uongozi, maeneo na matumizi ya mfumo.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (_, c) {
                  final count = c.maxWidth > 1050 ? 4 : (c.maxWidth > 650 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: count,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.35,
                    children: [
                      StatCard(
                        title: 'Wanachama Wote',
                        value: '${s.totalRulers}',
                        subtitle: 'Wote kwa mfumo',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primaryGreen,
                      ),
                      StatCard(
                        title: 'Viongozi',
                        value: '${s.totalLeaders}',
                        subtitle: '${s.leaderPercent.toStringAsFixed(1)}% ya jumla',
                        icon: Icons.workspace_premium_rounded,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        title: 'Mikoa',
                        value: '${s.totalRegions}',
                        subtitle: 'Mikoa iliyosajiliwa',
                        icon: Icons.location_city,
                        color: AppColors.primaryGreen,
                      ),
                      StatCard(
                        title: 'Matawi',
                        value: '${s.totalBranches}',
                        subtitle: 'Matawi yaliyosajiliwa',
                        icon: Icons.account_tree,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (_, c) {
                  final wide = c.maxWidth > 900;
                  final charts = [
                    const Expanded(flex: 1, child: _GenderPieCard()),
                    const SizedBox(width: 14, height: 14),
                    const Expanded(flex: 2, child: _RegistrationsBarCard()),
                  ];
                  return wide
                      ? IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: charts))
                      : const Column(children: [_GenderPieCard(), SizedBox(height: 14), _RegistrationsBarCard()]);
                }),
                const SizedBox(height: 14),
                const _RegionsBarCard(),
                const SizedBox(height: 20),
                const _RecentLoginsCard(),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _GenderPieCard extends StatelessWidget {
  const _GenderPieCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jinsia za Wanachama', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Obx(() {
              if (controller.isLoadingCharts.value) {
                return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
              }
              final points = controller.charts.value?.genderDistribution ?? [];
              final total = points.fold<int>(0, (sum, p) => sum + p.value);
              if (points.isEmpty || total == 0) {
                return const SizedBox(height: 160, child: Center(child: Text('Hakuna data bado.', style: TextStyle(color: AppColors.textSecondary))));
              }
              final colors = [AppColors.primaryGreen, AppColors.accentYellow, AppColors.info, AppColors.neutralGray];
              return SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 34,
                          sections: [
                            for (int i = 0; i < points.length; i++)
                              PieChartSectionData(
                                value: points[i].value.toDouble(),
                                title: '${(points[i].value / total * 100).toStringAsFixed(0)}%',
                                color: colors[i % colors.length],
                                radius: 54,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < points.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('${points[i].label} (${points[i].value})', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RegistrationsBarCard extends StatelessWidget {
  const _RegistrationsBarCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Usajili Mpya - Miezi 6 Iliyopita', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Obx(() {
              if (controller.isLoadingCharts.value) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final points = controller.charts.value?.registrationsByMonth ?? [];
              if (points.isEmpty) {
                return const SizedBox(height: 200, child: Center(child: Text('Hakuna data bado.', style: TextStyle(color: AppColors.textSecondary))));
              }
              final maxY = (points.map((p) => p.value).fold<int>(0, (a, b) => a > b ? a : b)).toDouble();
              return SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxY == 0 ? 5 : maxY * 1.2,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= points.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(points[i].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < points.length; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(toY: points[i].value.toDouble(), color: AppColors.primaryGreen, width: 22, borderRadius: BorderRadius.circular(4)),
                        ]),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RegionsBarCard extends StatelessWidget {
  const _RegionsBarCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wanachama kwa Mkoa (Top 8)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Obx(() {
              if (controller.isLoadingCharts.value) {
                return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
              }
              final points = controller.charts.value?.membersByRegion ?? [];
              if (points.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('Hakuna data bado (Wanachama hawajapewa Mkoa/RulerLocation).', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
                );
              }
              final maxY = (points.map((p) => p.value).fold<int>(0, (a, b) => a > b ? a : b)).toDouble();
              return SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    maxY: maxY == 0 ? 5 : maxY * 1.2,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= points.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(points[i].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < points.length; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(toY: points[i].value.toDouble(), color: AppColors.info, width: 26, borderRadius: BorderRadius.circular(4)),
                        ]),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RecentLoginsCard extends StatelessWidget {
  const _RecentLoginsCard();

  @override
  Widget build(BuildContext context) {
    // Inatumia moduli ya login_history iliyopo tayari - GetPage yake
    // haihitajiki hapa, tunatumia controller/service moja kwa moja.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Login za Karibuni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.loginHistory),
                  child: const Text('Tazama zote →'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Fungua "Historia ya Login" kwenye menu kuona orodha kamili.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
