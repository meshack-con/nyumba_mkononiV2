class ChartPointModel {
  final String label;
  final int value;
  ChartPointModel({required this.label, required this.value});

  factory ChartPointModel.fromJson(Map<String, dynamic> j) =>
      ChartPointModel(label: j['label'] as String, value: j['value'] as int);
}

class DashboardChartsModel {
  final List<ChartPointModel> genderDistribution;
  final List<ChartPointModel> leaderVsMember;
  final List<ChartPointModel> membersByRegion;
  final List<ChartPointModel> registrationsByMonth;

  DashboardChartsModel({
    required this.genderDistribution,
    required this.leaderVsMember,
    required this.membersByRegion,
    required this.registrationsByMonth,
  });

  factory DashboardChartsModel.fromJson(Map<String, dynamic> j) {
    List<ChartPointModel> parse(String key) =>
        (j[key] as List).map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>)).toList();
    return DashboardChartsModel(
      genderDistribution: parse('gender_distribution'),
      leaderVsMember: parse('leader_vs_member'),
      membersByRegion: parse('members_by_region'),
      registrationsByMonth: parse('registrations_by_month'),
    );
  }
}
