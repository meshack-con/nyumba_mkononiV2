import 'package:flutter/material.dart';

import '../models/property.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'add_property_screen.dart';
import 'auth_screen.dart';
import 'edit_property_screen.dart';
import 'messages_inbox_screen.dart';
import 'profile_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});
  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  List<Property> _properties = [];
  bool _loading = true;
  bool _checkingAuth = true;
  int _tab = 0;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    // Hakikisha mtumiaji ame-authenticate KABLA ya kuona dashibodi ya muuzaji.
    // Ikiwa tayari ana token iliyohifadhiwa (kutoka mara ya awali), hatahitaji
    // ku-login tena - ensureAuthenticated itapita moja kwa moja.
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  Future<void> _guard() async {
    final ok = await ensureAuthenticated(context, asSeller: true);
    if (!mounted) return;
    if (!ok) {
      // Mtumiaji hakukamilisha authentication (mfano amefunga dirisha la login) -
      // hatoingizwa kwenye dashibodi ya muuzaji, tunarudi nyuma.
      Navigator.pop(context);
      return;
    }
    setState(() => _checkingAuth = false);
    _load();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiClient.instance.getMe();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
      // Haihitaji kuvunja dashibodi ikiwa imeshindikana kupakia wasifu.
    }
  }

  Future<void> _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    _loadCurrentUser();
  }

  Future<void> _load() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) { if (mounted) setState(() => _loading = false); return; }
    try { final data = await ApiClient.instance.getMyProperties(); if (mounted) setState(() => _properties = data); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addProperty() async {
    // Kwa hatua hii mtumiaji tayari ame-authenticate (angeshaondolewa hapo awali
    // kama sivyo), lakini tunaacha ukaguzi huu kama ulinzi wa ziada.
    if (!await ensureAuthenticated(context, asSeller: true) || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
    _load();
  }

  Future<void> _editProperty(Property property) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditPropertyScreen(property: property)));
    if (changed == true) _load();
  }

  Future<void> _deleteProperty(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Futa tangazo?'),
        content: Text('Una uhakika unataka kufuta "${property.name}"? Hatua hii haiwezi kutenduliwa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Futa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient.instance.deleteProperty(property.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tangazo limefutwa.')));
        _load();
      }
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindikana kufuta tangazo.')));
    }
  }

  Future<void> _selectTab(int index) async {
    setState(() => _tab = index);
    // Ukirudi Dashibodi kutoka Ujumbe (baada ya kusoma/kujibu), sasisha
    // idadi za "unread" kwenye kadi za nyumba.
    if (index == 0) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      // Bado tunakagua kama mtumiaji ame-authenticate - onyesha loading tu,
      // usionyeshe maudhui ya dashibodi kabla ya uthibitisho.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalUnread = _properties.fold<int>(0, (sum, item) => sum + item.unreadMessagesCount);
    final chatIcon = const Icon(Icons.chat_bubble_outline_rounded);
    final chatIconSelected = const Icon(Icons.chat_bubble_rounded);
    return Scaffold(
      // AppBar inaonyeshwa tu kwenye tab ya Dashibodi - tab ya Ujumbe
      // ina header yake ya ndani (MessagesInboxScreen) ili kuepuka AppBar
      // mbili juu ya nyingine.
      appBar: _tab == 0
          ? AppBar(
              title: const Text('Dashibodi yako', style: TextStyle(fontWeight: FontWeight.w900)),
              actions: [
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                Padding(
                  padding: const EdgeInsets.only(right: 14, left: 4),
                  child: InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: _currentUser?.profilePichaUrl != null ? NetworkImage(_currentUser!.profilePichaUrl!) : null,
                      child: _currentUser?.profilePichaUrl == null
                          ? Text(
                              _currentUser?.fullName.isNotEmpty == true ? _currentUser!.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            )
          : null,
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(onPressed: _addProperty, backgroundColor: AppTheme.coral, foregroundColor: Colors.white, icon: const Icon(Icons.add_rounded), label: const Text('Weka nyumba'))
          : null,
      // Sehemu ya "Ujumbe" iko kwenye button bar chini (siyo juu kabisa) ili
      // ionekane kirahisi, na inaonyesha idadi ya notification (ujumbe
      // usiosomwa) juu ya icon yake.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashibodi'),
          NavigationDestination(
            icon: totalUnread > 0 ? Badge(label: Text('$totalUnread'), backgroundColor: AppTheme.coral, child: chatIcon) : chatIcon,
            selectedIcon: totalUnread > 0 ? Badge(label: Text('$totalUnread'), backgroundColor: AppTheme.coral, child: chatIconSelected) : chatIconSelected,
            label: 'Ujumbe',
          ),
        ],
      ),
      body: _tab == 0 ? _dashboardBody() : const MessagesInboxScreen(),
    );
  }

  Widget _dashboardBody() {
    final approved = _properties.where((item) => item.status == 'approved').length;
    final pending = _properties.where((item) => item.status == 'pending').length;
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
        Text(
          _currentUser != null ? 'Karibu, ${_currentUser!.fullName}' : 'Tangazo lako, mwanzo wa safari ya mtu.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 22),
        Row(children: [_Stat(label: 'Jumla', value: '${_properties.length}', color: AppTheme.primary), const SizedBox(width: 10), _Stat(label: 'Imeidhinishwa', value: '$approved', color: AppTheme.success), const SizedBox(width: 10), _Stat(label: 'Inapitiwa', value: '$pending', color: AppTheme.primaryContainer)]),
        const SizedBox(height: 28),
        Text('Mali zako', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(36), child: CircularProgressIndicator())) else if (_properties.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Column(children: [Icon(Icons.add_business_outlined, size: 48, color: AppTheme.muted), SizedBox(height: 12), Text('Bado hujaweka nyumba.', style: TextStyle(color: AppTheme.muted))])) else ..._properties.map((property) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: 70, height: 70, child: property.photoUrls.isEmpty ? const ColoredBox(color: AppTheme.sand, child: Icon(Icons.home)) : Image.network(ApiClient.instance.assetUrl(property.photoUrls.first), fit: BoxFit.cover))),
          title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${property.locationLabel}\n${property.formattedPrice}'),
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 4, children: [
                _MiniStat(icon: Icons.visibility_outlined, value: '${property.viewCount}'),
                _MiniStat(icon: Icons.favorite_outline_rounded, value: '${property.favoritesCount}'),
                if (property.unreadMessagesCount > 0) _MiniStat(icon: Icons.mark_chat_unread_outlined, value: '${property.unreadMessagesCount}', color: AppTheme.coral),
              ]),
            ]),
          ),
          isThreeLine: true,
          trailing: Column(mainAxisSize: MainAxisSize.min, children: [
            _StatusBadge(status: property.status),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.muted, size: 20),
              onSelected: (value) {
                if (value == 'edit') _editProperty(property);
                if (value == 'delete') _deleteProperty(property);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Hariri')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Futa', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ]),
        )))
    ]));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value; final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))])));
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, this.color});
  final IconData icon;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.muted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 3),
      Text(value, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status}); final String status;
  @override
  Widget build(BuildContext context) { final approved = status == 'approved'; final expired = status == 'expired'; final color = approved ? AppTheme.success : expired ? AppTheme.muted : AppTheme.primary; final label = approved ? 'Imeidhinishwa' : expired ? 'Imeisha' : 'Inapitiwa'; return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: color.withAlpha(31), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))); }
}
