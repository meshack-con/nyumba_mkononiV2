import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'buyer_home_screen.dart';
import 'seller_dashboard_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _enterAsSeller(BuildContext context) async {
    // Mtake mtumiaji afanye authentication KWANZA (impeleke auth_screen).
    // Kama akikataa/akafunga dirisha la login, hatoingizwa kwenye dashibodi.
    final ok = await ensureAuthenticated(context, asSeller: true);
    if (!ok || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karibu Nyumba Mkononi', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              children: [
                Text('Unaanza upande gani?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text('Chagua jukumu lako. Unaweza kuvinjari bila akaunti.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.muted)),
                const SizedBox(height: 34),
                _RoleCard(
                  icon: Icons.search_rounded,
                  title: 'Mpangaji au Mnunuzi',
                  description: 'Tafuta nyumba, linganisha chaguo na upate eneo lako linalofuata.',
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerHomeScreen())),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.add_business_rounded,
                  title: 'Muuzaji au Mpangishaji',
                  description: 'Weka mali yako mbele ya watu wanaotafuta nyumba Tanzania.',
                  color: AppTheme.coral,
                  onTap: () => _enterAsSeller(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.description, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(width: 62, height: 62, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.white, size: 30)),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted, height: 1.35))])),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
