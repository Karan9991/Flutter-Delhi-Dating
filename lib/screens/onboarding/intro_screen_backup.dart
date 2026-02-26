import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/local_storage_keys.dart';
import '../../providers.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _accent = Color(0xFFFF00FF);
  static const _canvas = Color(0xFFFFF1FC);

  final _controller = PageController();
  int _index = 0;

  static final List<_IntroSlide> _slides = [
    const _IntroSlide(
      title: 'Welcome to\nDelhi Dating',
      caption: 'Date in your local Delhi\narea around you',
      heroImage:
          'https://images.unsplash.com/photo-1496372412473-e8548ffd82bc?w=1200&auto=format&fit=crop',
      smallCircleImage:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300&auto=format&fit=crop',
      cornerImage:
          'https://images.unsplash.com/photo-1532712938310-34cb3982ef74?w=400&auto=format&fit=crop',
    ),
    const _IntroSlide(
      title: 'Discover your\nPerfect Match',
      caption: 'Get ready to discover\nyour ideal partner!',
      heroImage:
          'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=1200&auto=format&fit=crop',
      smallCircleImage:
          'https://images.unsplash.com/photo-1516589091380-5d8e87df6999?w=300&auto=format&fit=crop',
      cornerImage:
          'https://images.unsplash.com/photo-1522673607200-164d1b6ce486?w=400&auto=format&fit=crop',
    ),
    const _IntroSlide(
      title: 'LuvLink to\nEternal Bonds',
      caption: 'Meaningful connections\nstart with great conversations',
      heroImage:
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=1200&auto=format&fit=crop',
      smallCircleImage:
          'https://images.unsplash.com/photo-1520854221256-17451cc331bf?w=300&auto=format&fit=crop',
      cornerImage:
          'https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?w=400&auto=format&fit=crop',
    ),
  ];

  static const _palettes = [
    _SlidePalette(
      skyTop: Color(0xFFFFF7FD),
      skyMid: Color(0xFFFFDFF8),
      skyBottom: Color(0xFFFFB8EB),
      bloomLeft: Color(0x59FF00FF),
      bloomRight: Color(0x4DF26CFF),
      blobTop: Color(0xFFFFCAE4),
      blobBottom: Color(0xFFFFA8DC),
    ),
    _SlidePalette(
      skyTop: Color(0xFFFFF8FF),
      skyMid: Color(0xFFFFE5FB),
      skyBottom: Color(0xFFFFC0EF),
      bloomLeft: Color(0x4DFF00FF),
      bloomRight: Color(0x59FF72BC),
      blobTop: Color(0xFFFFCDEB),
      blobBottom: Color(0xFFFF9FDF),
    ),
    _SlidePalette(
      skyTop: Color(0xFFFFF8FE),
      skyMid: Color(0xFFFFDFF7),
      skyBottom: Color(0xFFFFB0E6),
      bloomLeft: Color(0x5CFF00FF),
      bloomRight: Color(0x4DFF87C4),
      blobTop: Color(0xFFFFC7E9),
      blobBottom: Color(0xFFFF9AD8),
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onActionPressed() async {
    if (_isLast) {
      await _finishIntro();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kIntroSeenStorageKey, true);
    if (!mounted) return;
    ref.read(onboardingSeenProvider.notifier).state = true;
    context.go('/delhi-access');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return _IntroCanvas(
                    slide: _slides[index],
                    palette: _palettes[index % _palettes.length],
                    accent: _accent,
                  );
                },
              ),
            ),
            _BottomControlBar(
              accent: _accent,
              index: _index,
              total: _slides.length,
              isLast: _isLast,
              onActionPressed: _onActionPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControlBar extends StatelessWidget {
  const _BottomControlBar({
    required this.accent,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onActionPressed,
  });

  final Color accent;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFFFEEFB).withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: accent.withValues(alpha: 0.24),
                width: 1.1,
              ),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonWidth = (constraints.maxWidth * 0.43).clamp(
                      154.0,
                      194.0,
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: _SlideDotsPanel(
                            accent: accent,
                            index: index,
                            total: total,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _FlowActionButton(
                          width: buttonWidth,
                          label: isLast ? 'GET STARTED' : 'NEXT',
                          onTap: onActionPressed,
                          accent: accent,
                          progress: (index + 1) / total,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideDotsPanel extends StatelessWidget {
  const _SlideDotsPanel({
    required this.accent,
    required this.index,
    required this.total,
  });

  final Color accent;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 1 ? 1.0 : (index + 1) / total;
    final current = (index + 1).toString().padLeft(2, '0');
    final pages = '$current / ${total.toString().padLeft(2, '0')}';

    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFFFECFB).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            left: 22,
            right: 22,
            child: IgnorePointer(
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [accent, const Color(0xFFFF8CF0)],
                    ).createShader(bounds),
                    child: Text(
                      'Explore',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.55,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.12),
                          accent.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      pages,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
                child: Row(
                  children: List.generate(total, (dotIndex) {
                    final active = dotIndex == index;
                    return Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          width: active ? 22 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: active
                                ? LinearGradient(
                                    colors: [accent, const Color(0xFFFF97F6)],
                                  )
                                : null,
                            color: active
                                ? null
                                : accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : accent.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.38),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: accent.withValues(alpha: 0.1)),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, const Color(0xFFFF86F2)],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.34),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroCanvas extends StatelessWidget {
  const _IntroCanvas({
    required this.slide,
    required this.palette,
    required this.accent,
  });

  final _IntroSlide slide;
  final _SlidePalette palette;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final heroTop = height * 0.24;
        final heroHeight = height * 0.47;

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.skyTop,
                      palette.skyMid,
                      palette.skyBottom,
                      palette.bloomLeft,
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.74, -0.88),
                    radius: 0.68,
                    colors: [palette.bloomLeft, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.84, 0.92),
                    radius: 0.85,
                    colors: [palette.bloomRight, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MeshGlowPainter(
                    accent: accent,
                    bloomLeft: palette.bloomLeft,
                    bloomRight: palette.bloomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 46, sigmaY: 46),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -88,
                        left: -116,
                        child: _GlowOrb(
                          size: 260,
                          color: accent.withValues(alpha: 0.24),
                        ),
                      ),
                      Positioned(
                        top: height * 0.34,
                        right: -90,
                        child: _GlowOrb(
                          size: 230,
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      Positioned(
                        bottom: -110,
                        left: width * 0.24,
                        child: _GlowOrb(
                          size: 280,
                          color: const Color(
                            0xFFFF86D7,
                          ).withValues(alpha: 0.19),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OrnamentPainter(
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 4,
              bottom: 6,
              child: ClipPath(
                clipper: _MainBlobClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.blobTop, palette.blobBottom],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: accent, width: 2.1),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.26),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // gradient: LinearGradient(
                      //   begin: Alignment.topCenter,
                      //   end: Alignment.bottomCenter,
                      //   colors: [
                      //     Colors.white.withValues(alpha: 0.28),
                      //     Colors.transparent,
                      //     Colors.black.withValues(alpha: 0.04),
                      //   ],
                      //   stops: const [0, 0.45, 1],
                      // ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: width * 0.34,
              top: 6,
              height: height * 0.19,
              child: ClipPath(
                clipper: _TopBubbleClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.96),
                        const Color(0xFFFFECFA).withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [accent, const Color(0xFFFF58D2)],
                      ).createShader(bounds),
                      child: Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              height: 1.16,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: 18, right: 18, child: _HeartStamp(accent: accent)),
            Positioned(
              top: height * 0.13,
              right: 22,
              child: _RingImage(
                url: slide.smallCircleImage,
                size: 92,
                borderColor: accent,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: heroTop,
              height: heroHeight,
              child: ClipPath(
                clipper: _HeroFrameClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 2.1),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFFFECFA).withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 1,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipPath(
                      clipper: _HeroFrameClipper(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _NetworkPhoto(url: slide.heroImage),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.22),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.42],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: heroHeight * 0.22,
                                decoration: BoxDecoration(
                                  // gradient: LinearGradient(
                                  //   colors: [
                                  //     Colors.white.withValues(alpha: 0.35),
                                  //     Colors.transparent,
                                  //   ],
                                  // ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _HeroTag(
                              accent: accent,
                              label: 'DELHI ONLY',
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 14,
                            right: 14,
                            child: IgnorePointer(
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  // gradient: LinearGradient(
                                  //   colors: [
                                  //     Colors.white.withValues(alpha: 0.28),
                                  //     Colors.transparent,
                                  //   ],
                                  // ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: height * 0.2,
              child: _RingImage(
                url: slide.smallCircleImage,
                size: 84,
                borderColor: accent,
              ),
            ),
            Positioned(
              left: 8,
              right: width * 0.3,
              bottom: height * 0.08,
              height: height * 0.15,
              child: ClipPath(
                clipper: _BottomBubbleClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFFFE7F8).withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Text(
                    slide.caption,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: accent,
                      height: 1.18,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: height * 0.09,
              child: ClipPath(
                clipper: _CornerImageClipper(),
                child: Container(
                  width: 96,
                  height: 124,
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 2),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.72),
                        const Color(0xFFFFD7F3).withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _NetworkPhoto(url: slide.cornerImage),
                ),
              ),
            ),
            Positioned(
              top: height * 0.31,
              right: 10,
              child: _DotTrail(color: accent),
            ),
            Positioned(top: 10, left: 18, child: _DotHeader(color: accent)),
            Positioned(
              top: height * 0.22,
              left: 14,
              child: _SparkleBurst(
                color: accent.withValues(alpha: 0.86),
                size: 24,
              ),
            ),
            Positioned(
              bottom: height * 0.23,
              right: width * 0.28,
              child: _SparkleBurst(
                color: accent.withValues(alpha: 0.68),
                size: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FlowActionButton extends StatelessWidget {
  const _FlowActionButton({
    required this.width,
    required this.label,
    required this.onTap,
    required this.accent,
    required this.progress,
  });

  final double width;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final start = Color.lerp(const Color(0xFFFF35E6), accent, progress)!;
    final middle = Color.lerp(
      const Color(0xFFFF00FF),
      const Color(0xFFFF40EC),
      progress,
    )!;
    final end = Color.lerp(
      const Color(0xFFFF7DF5),
      const Color(0xFFFF00DA),
      progress,
    )!;
    final buttonRadius = BorderRadius.circular(999);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: buttonRadius,
        onTap: onTap,
        child: Container(
          width: width,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: buttonRadius,
            gradient: LinearGradient(
              colors: [start, middle, end],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 3,
                left: 14,
                right: 14,
                child: IgnorePointer(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                fontSize: label.length > 8 ? 16 : 18,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.2),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
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

class _HeartStamp extends StatelessWidget {
  const _HeartStamp({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(10, (index) {
            final angle = index * 0.628;
            return Positioned(
              left: 52 + 34 * math.cos(angle) - 5,
              top: 52 + 34 * math.sin(angle) - 5,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          Icon(Icons.favorite_rounded, color: accent, size: 54),
        ],
      ),
    );
  }
}

class _RingImage extends StatelessWidget {
  const _RingImage({
    required this.url,
    required this.size,
    required this.borderColor,
  });

  final String url;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [borderColor, const Color(0xFFFF8AF3), borderColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: ClipOval(child: _NetworkPhoto(url: url)),
        ),
      ),
    );
  }
}

class _DotTrail extends StatelessWidget {
  const _DotTrail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        7,
        (_) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _DotHeader extends StatelessWidget {
  const _DotHeader({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, imageUrl) => Container(
        color: const Color(0xFFF5D6E8),
        alignment: Alignment.center,
        child: const Icon(Icons.favorite_outline_rounded),
      ),
      errorWidget: (context, imageUrl, error) => Container(
        color: const Color(0xFFF5D6E8),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const ui.Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withValues(alpha: 0.26),
                accent.withValues(alpha: 0.32),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkleBurst extends StatelessWidget {
  const _SparkleBurst({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.16,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Container(
            width: size,
            height: size * 0.16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeshGlowPainter extends CustomPainter {
  const _MeshGlowPainter({
    required this.accent,
    required this.bloomLeft,
    required this.bloomRight,
  });

  final Color accent;
  final Color bloomLeft;
  final Color bloomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final left = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.18, size.height * 0.24),
        size.width * 0.42,
        [bloomLeft.withValues(alpha: 0.45), Colors.transparent],
      );
    final right = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.84, size.height * 0.68),
        size.width * 0.38,
        [bloomRight.withValues(alpha: 0.42), Colors.transparent],
      );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.24),
      size.width * 0.42,
      left,
    );
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.68),
      size.width * 0.38,
      right,
    );

    final wave = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [accent.withValues(alpha: 0.24), accent.withValues(alpha: 0.08)],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pathA = Path()
      ..moveTo(-20, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.12,
        size.width * 0.48,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.36,
        size.width + 20,
        size.height * 0.28,
      );
    final pathB = Path()
      ..moveTo(-24, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.7,
        size.width * 0.56,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.98,
        size.width + 24,
        size.height * 0.9,
      );
    canvas.drawPath(pathA, wave);
    canvas.drawPath(pathB, wave);
  }

  @override
  bool shouldRepaint(covariant _MeshGlowPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.bloomLeft != bloomLeft ||
        oldDelegate.bloomRight != bloomRight;
  }
}

class _MainBlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.24, 0, size.width * 0.54, 56);
    path.quadraticBezierTo(
      size.width * 0.9,
      120,
      size.width,
      size.height * 0.36,
    );
    path.lineTo(size.width, size.height);
    path.quadraticBezierTo(
      size.width * 0.58,
      size.height,
      size.width * 0.4,
      size.height * 0.93,
    );
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.8,
      0,
      size.height * 0.56,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TopBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.8, 0);
    path.quadraticBezierTo(
      size.width * 0.96,
      size.height * 0.02,
      size.width,
      size.height * 0.28,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.78, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.45);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.86,
      -4,
      size.width,
      size.height * 0.34,
    );

    path.lineTo(size.width, size.height);
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height,
      0,
      size.height * 0.56,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroFrameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.58, 0);
    path.quadraticBezierTo(
      size.width * 0.88,
      0,
      size.width,
      size.height * 0.16,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.22, size.height);
    path.quadraticBezierTo(0, size.height * 0.83, 0, size.height * 0.56);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CornerImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.78, 0);
    path.lineTo(size.width, size.height * 0.18);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.22, size.height);
    path.lineTo(0, size.height * 0.78);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arcA = Rect.fromLTWH(
      -size.width * 0.15,
      size.height * 0.08,
      size.width * 0.9,
      size.height * 0.5,
    );
    canvas.drawArc(arcA, math.pi * 0.1, math.pi * 0.74, false, stroke);
    final arcB = Rect.fromLTWH(
      size.width * 0.34,
      size.height * 0.56,
      size.width * 0.86,
      size.height * 0.45,
    );
    canvas.drawArc(arcB, math.pi, math.pi * 0.58, false, stroke);

    for (var i = 0; i < 16; i++) {
      final dx = 20 + (i * 23.0) % (size.width - 40);
      final dy = size.height * 0.12 + ((i * 31.0) % (size.height * 0.72));
      final radius = i.isEven ? 2.2 : 1.4;
      canvas.drawCircle(Offset(dx, dy), radius, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SlidePalette {
  const _SlidePalette({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.bloomLeft,
    required this.bloomRight,
    required this.blobTop,
    required this.blobBottom,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color bloomLeft;
  final Color bloomRight;
  final Color blobTop;
  final Color blobBottom;
}

class _IntroSlide {
  const _IntroSlide({
    required this.title,
    required this.caption,
    required this.heroImage,
    required this.smallCircleImage,
    required this.cornerImage,
  });

  final String title;
  final String caption;
  final String heroImage;
  final String smallCircleImage;
  final String cornerImage;
}
