import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _controller = PageController();
  int _page = 0;
  Timer? _autoSlideTimer;

  // Muda wa kusubiri kabla ya kubadili slide kiotomatiki.
  static const _autoSlideDuration = Duration(seconds: 4);

  final _slides = const [
    ('01', 'Pata mahali pa kuishi', 'Vinjari nyumba na vyumba vilivyopangiliwa kwa maeneo unayoyajua.'),
    ('02', 'Chagua kwa uhakika', 'Linganisha bei, aina ya nyumba, Wi-Fi na maelezo yote muhimu.'),
    ('03', 'Hamisha maisha yako', 'Wasiliana na mwenye nyumba kwa hatua inayofuata, ukiwa tayari.'),
  ];

  final _images = const [
    'assets/images/splash_1.png',
    'assets/images/splash_2.png',
    'assets/images/splash_3.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Inaanzisha (au kuanzisha upya) timer ya kubadili slide kiotomatiki.
  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(_autoSlideDuration, (_) {
      if (_page == _slides.length - 1) {
        _goToRoleSelection();
      } else {
        _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
  }

  void _goToRoleSelection() {
    _autoSlideTimer?.cancel();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
  }

  // Kitufe "Endelea": kinabadilisha slide papo hapo na kurudisha muda wa auto-slide mwanzo.
  void _next() {
    if (_page == _slides.length - 1) {
      _goToRoleSelection();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      _startAutoSlide();
    }
  }

  // Kitufe "Rudi": kinarudisha slide iliyopita (au kutoka splash ikiwa ni ya kwanza).
  void _back() {
    if (_page == 0) {
      _goToRoleSelection();
    } else {
      _controller.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      _startAutoSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Picha za background - full screen, zinabadilika kwa swipe au auto-slide
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (value) {
              setState(() => _page = value);
              _startAutoSlide();
            },
            itemBuilder: (context, index) {
              // Picha inajaza kioo kizima bila kuachwa nafasi tupu (BoxFit.cover),
              // na alignment ya juu ili logo/kichwa cha habari kwenye picha kisikatwe.
              return Image.asset(
                _images[index],
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // Gradient nyeusi ndogo chini, kwa ajili ya dots na buttons pekee
          // (picha zenyewe tayari zina maandishi yanayoelezea huduma).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),

          // Dots + buttons, juu ya gradient (bila maandishi ya ziada)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                  child: Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        height: 7,
                        width: index == _page ? 28 : 7,
                        decoration: BoxDecoration(
                          color: index == _page ? AppTheme.coral : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Buttons: Rudi (kushoto) na Endelea (kulia)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(AppStrings.t('back')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.coral,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(_page == _slides.length - 1 ? AppStrings.t('start') : AppStrings.t('continueButton')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
