import 'package:flutter/material.dart';

import '../models/property.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'add_property_screen.dart';
import 'auth_screen.dart';
import 'edit_property_screen.dart';
import 'messages_inbox_screen.dart';
import 'personal_info_screen.dart';

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

  /// Kubonyeza herufi ya kwanza ya jina (avatar) juu ya dashibodi kunampeleka
  /// mtumiaji moja kwa moja kwenye "Taarifa binafsi" zake.
  Future<void> _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
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
    // Fomu ya "Weka nyumba" inaonyeshwa kama kadi (card) inayopanda kutoka
    // chini ya skrini - siyo ukurasa mpya - mara tu mtumiaji anapobonyeza
    // kitufe hiki.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPropertyScreen(),
    );
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
              actions: [
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
      // Kitufe cha "Weka nyumba" cha FAB (chini kulia) kinaonekana TU baada
      // ya mtumiaji kuwa na nyumba moja au zaidi. Kabla ya hapo, kitufe
      // pekee cha kuweka nyumba ni kile cha katikati ndani ya "empty state"
      // (_emptyState) - kamwe visionekane vyote viwili kwa wakati mmoja.
      floatingActionButton: _tab == 0 && !_loading && _properties.isNotEmpty
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

  // ---------------------------------------------------------------------
  // MUONEKANO (UI) MPYA WA DASHIBODI - mantiki/ma-API calls hayajabadilika,
  // sehemu hii inahusu tu jinsi taarifa zinavyopangwa kwenye skrini.
  // ---------------------------------------------------------------------

  Widget _dashboardBody() {
    final approved = _properties.where((item) => item.status == 'approved').length;
    final pending = _properties.where((item) => item.status == 'pending').length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          _welcomeCard(approved, pending),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mali zako', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              if (_properties.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(20)),
                  child: Text('${_properties.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.muted)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(46), child: CircularProgressIndicator()))
          else if (_properties.isEmpty)
            _emptyState()
          else
            ..._properties.map(_propertyCard),
        ],
      ),
    );
  }

  /// Kadi ya karibisho juu ya dashibodi - inaonyesha jina la mtumiaji na
  /// takwimu tatu kuu kwa mtazamo mmoja, kwa muonekano wa kisasa zaidi
  /// kuliko masanduku matatu ya awali.
  Widget _welcomeCard(int approved, int pending) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.72)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser != null ? 'Karibu, ${_currentUser!.fullName.split(' ').first}' : 'Karibu tena',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Fuatilia matangazo yako ya nyumba hapa.',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _StatChip(icon: Icons.home_work_rounded, value: '${_properties.length}', label: 'Jumla'),
                const SizedBox(width: 10),
                _StatChip(icon: Icons.verified_rounded, value: '$approved', label: 'Imeidhinishwa'),
                const SizedBox(width: 10),
                _StatChip(icon: Icons.hourglass_top_rounded, value: '$pending', label: 'Inapitiwa'),
              ],
            ),
          ],
        ),
      );

  /// Muonekano mpya wa "hakuna nyumba bado" - una kitufe cha moja kwa moja
  /// cha kuongeza tangazo la kwanza.
  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.sand),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppTheme.sand, shape: BoxShape.circle),
              child: const Icon(Icons.add_home_work_outlined, size: 34, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            const Text('Bado hujaweka nyumba', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Anza kwa kuongeza tangazo la kwanza la nyumba yako.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _addProperty,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Weka nyumba'),
            ),
          ],
        ),
      );

  /// Kadi moja ya nyumba - imepangwa upya kwa muonekano wa kisasa zaidi
  /// (picha kubwa zaidi, kivuli laini, taarifa zilizopangiliwa vizuri) huku
  /// vitendo vyote (Hariri / Futa) vikibaki vilevile kimantiki.
  Widget _propertyCard(Property property) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 88,
                height: 88,
                child: property.photoUrls.isEmpty
                    ? const ColoredBox(color: AppTheme.sand, child: Icon(Icons.home_rounded, color: AppTheme.muted))
                    : Image.network(ApiClient.instance.assetUrl(property.photoUrls.first), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _StatusBadge(status: property.status),
                      const SizedBox(width: 8),
                      const Icon(Icons.place_outlined, size: 13, color: AppTheme.muted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.muted, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.formattedPrice,
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 14.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _MiniStat(icon: Icons.visibility_outlined, value: '${property.viewCount}'),
                      _MiniStat(icon: Icons.favorite_outline_rounded, value: '${property.favoritesCount}'),
                      if (property.unreadMessagesCount > 0)
                        _MiniStat(icon: Icons.mark_chat_unread_outlined, value: '${property.unreadMessagesCount}', color: AppTheme.coral),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Chip ndogo yenye ikoni, thamani na lebo - inatumika kwenye kadi ya
/// karibisho (welcome card) juu ya dashibodi.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10),
              ),
            ],
          ),
        ),
      );
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
  Widget build(BuildContext context) { final approved = status == 'approved'; final expired = status == 'expired'; final color = approved ? AppTheme.success : expired ? AppTheme.muted : AppTheme.primary; final label = approved ? 'Imeidhinishwa' : expired ? 'Imeisha' : 'Inapitiwa'; return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(31), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800))); }
}
