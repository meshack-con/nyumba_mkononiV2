import 'package:flutter/material.dart';

import '../../../core/widgets/app_shell.dart';
import '../../settings_hub/widgets/stakeholder_split_panel.dart';

/// "Wadau" kama ukurasa wake MWENYEWE (siyo tena tabo ndani ya "Usanidi
/// wa Mfumo") - sasa iko chini ya kundi la "Usajili" kwenye sidebar,
/// pamoja na "Wanachama" na "Uthibitisho wa Uongozi".
class WadauView extends StatelessWidget {
  const WadauView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Wadau',
      child: StakeholderSplitPanel(),
    );
  }
}
