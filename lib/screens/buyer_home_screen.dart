import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/property.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'auth_screen.dart';
import 'favorites_screen.dart';
import 'help_assistant_screen.dart';
import 'messages_inbox_screen.dart';
import 'profile_screen.dart';
import 'property_details_screen.dart';

/// Buyer home screen.
/// UI adjusted to closely match the supplied Nyumba Mkononi reference:
/// - Active/hovered rent/sale button becomes bold and pink.
/// - Category chips become heavier when active.
/// - Property cards are shorter.
/// - Property image area is shorter.
/// - Existing API/search/favourite/navigation behavior is preserved.
class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final TextEditingController _search = TextEditingController();

  List<Property> _properties = [];
  Set<int> _favoriteIds = {};

  bool _loading = true;
  String? _error;

  String? _mode;
  String? _type;

  // Hover state for desktop Linux/Windows/macOS.
  String? _hoveredMode;

  int? _minPrice;
  int? _maxPrice;

  bool? _wifi;
  bool? _carParking;
  bool? _indoorToilet;
  bool? _hasElectricity;
  bool? _waterInside;
  bool? _waterNearby;
  bool? _furnished;
  bool? _swimmingPool;

  String? _postedWithin;

  int _tab = 0;
  int _unreadMessages = 0;
  AppUser? _currentUser;

  static Color get _pink => AppTheme.primary;
  static Color get _pinkDark => AppTheme.primaryContainer;
  static const Color _navy = Color(0xFF10234D);
  static const Color _muted = Color(0xFF65708A);
  static const Color _page = Color(0xFFF8F7FA);

  @override
  void initState() {
    super.initState();
    _load();
    _refreshUnreadBadge();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _currentUser = null);
      return;
    }
    try {
      final user = await ApiClient.instance.getMe();
      await ThemeController.instance.loadForUser(user.id);
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
      // Token isiyo sahihi au tatizo la mtandao - inabaki kuonyesha
      // hali ya "Mgeni" bila kuvunja skrini.
    }
  }

  Future<void> _refreshUnreadBadge() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) return;
    final count = await ApiClient.instance.getUnreadMessagesCount();
    if (mounted) setState(() => _unreadMessages = count);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final properties = await ApiClient.instance.getProperties(
        location: _search.text.trim(),
        propertyType: _type,
        mode: _mode,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        hasWifi: _wifi,
        carParking: _carParking,
        indoorToilet: _indoorToilet,
        hasElectricity: _hasElectricity,
        waterInside: _waterInside,
        waterNearby: _waterNearby,
        furnished: _furnished,
        swimmingPool: _swimmingPool,
        postedWithin: _postedWithin,
      );

      final token = await ApiClient.instance.getToken();

      var favorites = <FavoriteItem>[];

      if (token != null && token.isNotEmpty) {
        try {
          favorites = await ApiClient.instance.getFavorites();
        } on ApiException {
          // Do not make the home screen fail just because the saved
          // authentication token has expired/been rejected.
          favorites = <FavoriteItem>[];
        }
      }

      if (!mounted) return;

      setState(() {
        _properties = properties;
        _favoriteIds = favorites.map((e) => e.property.id).toSet();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Property property) async {
    if (!await ensureAuthenticated(
      context,
      asSeller: false,
    )) {
      return;
    }

    try {
      if (_favoriteIds.contains(property.id)) {
        await ApiClient.instance.removeFavorite(property.id);

        if (!mounted) return;

        setState(() {
          _favoriteIds.remove(property.id);
        });
      } else {
        await ApiClient.instance.addFavorite(property.id);

        if (!mounted) return;

        setState(() {
          _favoriteIds.add(property.id);
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (_tab) {
      case 1:
        content = const FavoritesScreen();
        break;

      case 2:
        content = const MessagesInboxScreen();
        break;

      case 3:
        content = const HelpAssistantScreen();
        break;

      case 4:
        content = const ProfileScreen();
        break;

      default:
        content = _buildHome();
    }

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 850;

    if (useRail) {
      return Scaffold(
        backgroundColor: _page,
        body: Row(
          children: [
            _navigationRail(),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _page,
      body: content,
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  // Tabs ambazo zinahitaji mtumiaji awe ameshaingia (auth) kabla ya
  // kuzifikia: Pendwa (favorites zake), Ujumbe (mazungumzo yake), Wasifu
  // (akaunti yake). Tafuta na Msaada zinabaki wazi kwa wageni.
  static const Set<int> _authRequiredTabs = {1, 2, 4};

  Future<void> _selectTab(int index) async {
    if (_authRequiredTabs.contains(index)) {
      final ok = await ensureAuthenticated(context, asSeller: false);
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    setState(() {
      _tab = index;
    });
    // Baada ya kuchagua tab (hasa ukitoka kwenye Ujumbe baada ya kusoma),
    // sasisha alama ya idadi ya ujumbe usiosomwa na taarifa za mtumiaji
    // (mfano baada ya kuingia au kuhariri wasifu).
    _refreshUnreadBadge();
    _loadCurrentUser();
  }

  Widget _navigationRail() {
    return NavigationRail(
      selectedIndex: _tab,
      onDestinationSelected: (index) {
        _selectTab(index);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: _pink),
      unselectedIconTheme: const IconThemeData(color: _navy),
      selectedLabelTextStyle: TextStyle(
        color: _pink,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: _navy,
        fontSize: 11,
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.search_rounded),
          label: Text('Tafuta'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: Text('Pendwa'),
        ),
        NavigationRailDestination(
          icon: _unreadMessages > 0
              ? Badge(label: Text('$_unreadMessages'), backgroundColor: _pink, child: const Icon(Icons.chat_bubble_outline_rounded))
              : const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: _unreadMessages > 0
              ? Badge(label: Text('$_unreadMessages'), backgroundColor: _pink, child: const Icon(Icons.chat_bubble_rounded))
              : const Icon(Icons.chat_bubble_rounded),
          label: const Text('Ujumbe'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent_rounded),
          label: Text('Msaada'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Wasifu'),
        ),
      ],
    );
  }

  Widget _bottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _bottomItem(
                index: 0,
                icon: Icons.search_rounded,
                label: 'Tafuta',
              ),
              _bottomItem(
                index: 1,
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Zilizohifadhiwa',
              ),
              _bottomItem(
                index: 2,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Ujumbe',
                badgeCount: _unreadMessages,
              ),
              _bottomItem(
                index: 3,
                icon: Icons.support_agent_outlined,
                activeIcon: Icons.support_agent_rounded,
                label: 'Msaada',
              ),
              _bottomItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Wasifu',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomItem({
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final selected = _tab == index;
    final iconWidget = Icon(
      selected ? (activeIcon ?? icon) : icon,
      size: 21,
      color: selected ? _pink : _navy,
    );

    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? _pink.withOpacity(.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: badgeCount > 0
                  ? Badge(
                      label: Text('$badgeCount'),
                      backgroundColor: _pink,
                      child: iconWidget,
                    )
                  : iconWidget,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? _pink : _navy,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return RefreshIndicator(
      color: _pink,
      backgroundColor: Colors.white,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _hero(),
          ),
          SliverToBoxAdapter(
            child: _categoryBar(),
          ),
          SliverToBoxAdapter(
            child: _propertiesSection(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 850;

    // The image ends before the search card. This prevents the
    // background from continuing underneath the full search/buttons area.
    // Reduced so the search card sits closer to the header above it, and
    // the filter chips (_categoryBar, which follows this sliver) move up too.
    final heroHeight = desktop ? 255.0 : 270.0;
    final imageHeight = desktop ? 195.0 : 205.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // BACKGROUND IMAGE ONLY.
          // It deliberately stops before the search card.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: imageHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background_1.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(.74),
                          Colors.white.withOpacity(.40),
                          Colors.white.withOpacity(.08),
                          Colors.transparent,
                        ],
                        stops: const [
                          0,
                          .35,
                          .78,
                          1,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header/title stays over the image.
          Positioned(
            left: desktop ? 24 : 18,
            right: desktop ? 24 : 18,
            top: top + 10,
            child: desktop
                ? _desktopHeaderOnly()
                : _mobileHeaderOnly(),
          ),

          // Search card is now completely separate from the image.
          Positioned(
            left: desktop ? 22 : 10,
            right: desktop ? 22 : 10,
            top: desktop ? 125 : 140,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1210,
                ),
                child: _searchPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopHeaderOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _brand(),
            const Spacer(),
            _loginButton(),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Tafuta nyumba, viwanja na fursa bora za makazi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _navy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Nyumba Mkononi – Mahali sahihi kwa mahitaji yako ya makazi',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _mobileHeaderOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _brand()),
            _loginButton(),
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          'Tafuta nyumba, viwanja na fursa bora za makazi',
          style: TextStyle(
            color: _navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Nyumba Mkononi – Mahali sahihi kwa mahitaji yako ya makazi',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _brand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: _pink,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Karibu,',
              style: TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _currentUser?.fullName ?? 'Mgeni',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _pinkDark,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loginButton() {
    if (_currentUser != null) {
      return InkWell(
        onTap: () => _selectTab(4),
        borderRadius: BorderRadius.circular(30),
        child: CircleAvatar(
          radius: 21,
          backgroundColor: _pink,
          backgroundImage: _currentUser!.profilePichaUrl != null ? NetworkImage(_currentUser!.profilePichaUrl!) : null,
          child: _currentUser!.profilePichaUrl == null
              ? Text(
                  _currentUser!.fullName.isNotEmpty ? _currentUser!.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                )
              : null,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthScreen(),
          ),
        );
        _loadCurrentUser();
        _refreshUnreadBadge();
      },
      icon: const Icon(
        Icons.person_outline_rounded,
        size: 17,
      ),
      label: const Text(
        'Ingia',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        minimumSize: const Size(
          0,
          38,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }

  Widget _searchPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _pink.withOpacity(.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              style: const TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Dar es Salaam, Kariakoo...',
                hintStyle: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _pink,
                  size: 21,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(5),
                  child: IconButton(
                    onPressed: _showFilters,
                    tooltip: 'Vichujio',
                    style: IconButton.styleFrom(
                      backgroundColor: _pink.withOpacity(.08),
                      foregroundColor: _pink,
                    ),
                    icon: const Icon(
                      Icons.tune_rounded,
                      size: 20,
                    ),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: _pink,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Two independent buttons.
          // They no longer look like one segmented control.
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  'Kwa Kupanga',
                  'rent',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeButton(
                  'Kwa Kununua',
                  'sale',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String label,
    String value,
  ) {
    final selected = _mode == value;
    final hovered = _hoveredMode == value;
    final active = selected || hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() {
          _hoveredMode = value;
        });
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _hoveredMode = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = selected ? null : value;
          });
          _load();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 43,
          decoration: BoxDecoration(
            color: active
                ? _pink
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active
                  ? _pink
                  : const Color(0xFFE0DDE2),
              width: 1,
            ),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: _pink.withOpacity(.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value == 'rent'
                    ? Icons.key_rounded
                    : Icons.home_rounded,
                color: active
                    ? Colors.white
                    : _pink,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : _pink,
                  fontSize: 12,
                  fontWeight: active
                      ? FontWeight.w900
                      : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryBar() {
    final categories = <String, String>{
      'Zote': '',
      'Chumba': 'chumba',
      'Nyumba': 'nyumba',
      'Kiwanja': 'kiwanja',
    };

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          22,
          4,
          22,
          8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return SizedBox(
              width: 44,
              child: IconButton.filled(
                onPressed: _showFilters,
                style: IconButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 19,
                ),
              ),
            );
          }

          final entry = categories.entries.elementAt(index);
          final selected = (_type ?? '') == entry.value;

          return ChoiceChip(
            selected: selected,
            onSelected: (_) {
              setState(() {
                _type = entry.value.isEmpty
                    ? null
                    : entry.value;
              });

              _load();
            },
            selectedColor: _pink,
            showCheckmark: false,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? _pink
                  : Colors.black.withOpacity(.06),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 3,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  )
                else if (entry.key == 'Chumba')
                  const Icon(
                    Icons.bed_rounded,
                    color: _navy,
                    size: 15,
                  )
                else if (entry.key == 'Nyumba')
                  const Icon(
                    Icons.home_rounded,
                    color: _navy,
                    size: 15,
                  )
                else if (entry.key == 'Kiwanja')
                  const Icon(
                    Icons.landscape_rounded,
                    color: _navy,
                    size: 15,
                  ),
                if (entry.key != 'Zote')
                  const SizedBox(width: 5),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _navy,
                    fontWeight: selected
                        ? FontWeight.w900
                        : FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _propertiesSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 70,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _EmptyState(
        icon: Icons.cloud_off_rounded,
        message: _error!,
        action: _load,
      );
    }

    if (_properties.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        message:
            'Hakuna matangazo yanayolingana na utafutaji wako.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1150
            ? 4
            : width >= 820
                ? 3
                : width >= 560
                    ? 2
                    : 1;

        final horizontal = width >= 700
            ? 22.0
            : 16.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            2,
            horizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'Mali zilizothibitishwa',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(.08),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_properties.length} nyumba',
                      style: TextStyle(
                        color: _pink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: _properties.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,

                  // Card size trimmed back down (kept the photo larger
                  // than the text below it, but the overall card is
                  // more compact again).
                  childAspectRatio:
                      width < 560
                          ? 1.20
                          : 1.28,
                ),
                itemBuilder: (context, index) {
                  final property =
                      _properties[index];

                  return _PropertyCard(
                    property: property,
                    favorite: _favoriteIds
                        .contains(property.id),
                    onFavorite: () =>
                        _toggleFavorite(property),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PropertyDetailsScreen(
                            property: property,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilters() {
    final min = TextEditingController(
      text: _minPrice == null
          ? ''
          : _formatThousands(_minPrice!),
    );

    final max = TextEditingController(
      text: _maxPrice == null
          ? ''
          : _formatThousands(_maxPrice!),
    );

    bool? wifi = _wifi;
    bool? parking = _carParking;
    bool? toilet = _indoorToilet;
    bool? electricity = _hasElectricity;
    bool? waterInside = _waterInside;
    bool? waterNearby = _waterNearby;
    bool? furnished = _furnished;
    bool? pool = _swimmingPool;
    String? posted = _postedWithin;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget switchTile(
              String label,
              IconData icon,
              bool? value,
              ValueChanged<bool> onChanged,
            ) {
              return SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  icon,
                  color: _pink,
                ),
                title: Text(
                  label,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: value ?? false,
                activeColor: _pink,
                onChanged: (v) {
                  setSheetState(() {
                    onChanged(v);
                  });
                },
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  5,
                  20,
                  22 +
                      MediaQuery.viewInsetsOf(
                        context,
                      ).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vichujio',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chagua vigezo unavyotaka. Si lazima uchague vyote.',
                        style: TextStyle(
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bei (TZS)',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: min,
                              keyboardType:
                                  TextInputType.number,
                              inputFormatters: [
                                _ThousandsInputFormatter(),
                              ],
                              decoration:
                                  const InputDecoration(
                                prefixText: 'Tsh ',
                                labelText: 'Kuanzia',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: max,
                              keyboardType:
                                  TextInputType.number,
                              inputFormatters: [
                                _ThousandsInputFormatter(),
                              ],
                              decoration:
                                  const InputDecoration(
                                prefixText: 'Tsh ',
                                labelText: 'Hadi',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Tangazo limewekwa lini',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          (
                            'Wakati wowote',
                            null,
                          ),
                          ('Leo', 'today'),
                          ('Wiki hii', 'week'),
                          ('Mwezi huu', 'month'),
                          ('Mwaka huu', 'year'),
                        ].map((item) {
                          final selected =
                              posted == item.$2;

                          return ChoiceChip(
                            selected: selected,
                            selectedColor: _pink,
                            showCheckmark: false,
                            label: Text(
                              item.$1,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : _navy,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                            onSelected: (_) {
                              setSheetState(() {
                                posted = item.$2;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Huduma zinazohitajika',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      switchTile(
                        'Wi-Fi',
                        Icons.wifi_rounded,
                        wifi,
                        (v) =>
                            wifi = v ? true : null,
                      ),
                      switchTile(
                        'Sehemu ya kuegesha gari',
                        Icons.local_parking_rounded,
                        parking,
                        (v) => parking =
                            v ? true : null,
                      ),
                      switchTile(
                        'Choo cha ndani',
                        Icons.wc_rounded,
                        toilet,
                        (v) => toilet =
                            v ? true : null,
                      ),
                      switchTile(
                        'Umeme',
                        Icons.bolt_rounded,
                        electricity,
                        (v) => electricity =
                            v ? true : null,
                      ),
                      switchTile(
                        'Maji ndani',
                        Icons.water_drop_rounded,
                        waterInside,
                        (v) => waterInside =
                            v ? true : null,
                      ),
                      switchTile(
                        'Maji karibu',
                        Icons.water_drop_outlined,
                        waterNearby,
                        (v) => waterNearby =
                            v ? true : null,
                      ),
                      switchTile(
                        'Samani (furnished)',
                        Icons.chair_rounded,
                        furnished,
                        (v) => furnished =
                            v ? true : null,
                      ),
                      switchTile(
                        'Swimming pool',
                        Icons.pool_rounded,
                        pool,
                        (v) => pool =
                            v ? true : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  min.clear();
                                  max.clear();
                                  wifi = null;
                                  parking = null;
                                  toilet = null;
                                  electricity = null;
                                  waterInside = null;
                                  waterNearby = null;
                                  furnished = null;
                                  pool = null;
                                  posted = null;
                                });
                              },
                              child: const Text(
                                'Futa vichujio',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style:
                                  FilledButton.styleFrom(
                                backgroundColor: _pink,
                              ),
                              onPressed: () {
                                setState(() {
                                  _minPrice =
                                      _parseThousands(
                                    min.text,
                                  );
                                  _maxPrice =
                                      _parseThousands(
                                    max.text,
                                  );
                                  _wifi = wifi;
                                  _carParking =
                                      parking;
                                  _indoorToilet =
                                      toilet;
                                  _hasElectricity =
                                      electricity;
                                  _waterInside =
                                      waterInside;
                                  _waterNearby =
                                      waterNearby;
                                  _furnished =
                                      furnished;
                                  _swimmingPool = pool;
                                  _postedWithin =
                                      posted;
                                });

                                Navigator.pop(
                                  sheetContext,
                                );

                                _load();
                              },
                              child: const Text(
                                'Tafuta',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatThousands(int value) {
    return value.toString().replaceAllMapped(
          RegExp(
            r'(\d)(?=(\d{3})+(?!\d))',
          ),
          (m) => '${m[1]},',
        );
  }

  int? _parseThousands(String text) {
    final digits = text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) return null;

    return int.tryParse(digits);
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final Property property;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  static Color get pink => AppTheme.primary;
  static const Color navy = Color(0xFF10234D);
  static const Color muted = Color(0xFF65708A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withOpacity(.045),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.055),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Photo area: still bigger than the name/price text below
              // it, but smaller overall than before so the whole card
              // is more compact.
              SizedBox(
                height: 145,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (property.photoUrls.isEmpty)
                      const ColoredBox(
                        color: Color(0xFFF1F2F5),
                        child: Icon(
                          Icons.home_work_rounded,
                          size: 42,
                          color: muted,
                        ),
                      )
                    else
                      Image.network(
                        ApiClient.instance.assetUrl(
                          property.photoUrls.first,
                        ),
                        fit: BoxFit.cover,
                        filterQuality:
                            FilterQuality.high,
                        errorBuilder:
                            (_, __, ___) {
                          return const ColoredBox(
                            color: Color(0xFFF1F2F5),
                            child: Icon(
                              Icons.home_work_rounded,
                              size: 42,
                              color: muted,
                            ),
                          );
                        },
                      ),

                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: pink,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons
                                  .check_circle_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property.status ==
                                      'approved'
                                  ? 'Imethibitishwa'
                                  : 'Inapitiwa',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      right: 8,
                      top: 7,
                      child: Material(
                        color: Colors.white,
                        shape:
                            const CircleBorder(),
                        child: InkWell(
                          customBorder:
                              const CircleBorder(),
                          onTap: onFavorite,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons
                                  .favorite_border_rounded,
                              color: navy,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (favorite)
                      Positioned(
                        right: 8,
                        top: 7,
                        child: Material(
                          color: Colors.white,
                          shape:
                              const CircleBorder(),
                          child: InkWell(
                            customBorder:
                                const CircleBorder(),
                            onTap: onFavorite,
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                Icons
                                    .favorite_rounded,
                                color: pink,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    11,
                    8,
                    11,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons
                                .location_on_outlined,
                            size: 13,
                            color: muted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              property.locationLabel,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  TextStyle(
                                color: muted,
                                fontSize: 10.5,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              property.mode ==
                                      'rent'
                                  ? '${property.formattedPrice} / mwezi'
                                  : property.formattedPrice,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  TextStyle(
                                color: pink,
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons
                                .arrow_forward_rounded,
                            size: 15,
                            color: pink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final VoidCallback? action;

  static const Color muted =
      Color(0xFF65708A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 55,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 45,
            color: muted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action,
              child: const Text(
                'Jaribu tena',
              ),
            ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 52,
              color: Color(0xFFD5005B),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sehemu hii itakuwa tayari baada ya kuwasiliana na mwenye nyumba.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF65708A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
      );
    }

    final formatted = digits.replaceAllMapped(
      RegExp(
        r'(\d)(?=(\d{3})+(?!\d))',
      ),
      (match) => '${match[1]},',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
