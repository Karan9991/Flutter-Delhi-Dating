import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/profile_detail_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final List<UserProfile> _queue = [];
  final Set<String> _swipedIds = {};
  bool _processing = false;
  bool _isAnimating = false;
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0;
  late final AnimationController _swipeController;
  Animation<Offset>? _swipeOffsetAnimation;
  Animation<double>? _swipeRotationAnimation;
  double _maxDistance = 25;
  RangeValues _ageRange = const RangeValues(22, 35);

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _swipeController.addListener(() {
      if (_swipeOffsetAnimation == null) return;
      setState(() {
        _dragOffset = _swipeOffsetAnimation!.value;
        _dragRotation = _swipeRotationAnimation?.value ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  Future<void> _processSwipe({
    required UserProfile profile,
    required bool liked,
  }) async {
    if (_processing) return;
    setState(() => _processing = true);

    final auth = ref.read(authStateProvider).value;
    if (auth != null) {
      if (liked) {
        await ref
            .read(matchingServiceProvider)
            .likeUser(currentUid: auth.uid, otherUid: profile.id);
      } else {
        await ref
            .read(matchingServiceProvider)
            .passUser(currentUid: auth.uid, otherUid: profile.id);
      }
    }

    if (mounted) {
      setState(() => _processing = false);
      if (_queue.isEmpty) {
        ref.invalidate(discoverProfilesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.tune)),
        ],
      ),
      body: discoverState.when(
        data: (profiles) {
          if (_queue.isEmpty && profiles.isNotEmpty) {
            _queue.addAll(
              profiles.where(
                (profile) =>
                    !_swipedIds.contains(profile.id) &&
                    profile.age >= _ageRange.start &&
                    profile.age <= _ageRange.end,
              ),
            );
          }

          if (_queue.isEmpty) {
            return const EmptyState(
              title: 'No one new right now',
              subtitle: 'Check back soon or update your filters.',
              icon: Icons.public,
            );
          }

          final profile = _queue.first;
          return Stack(
            children: [
              Positioned(
                top: -30,
                right: -12,
                child: IgnorePointer(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -30,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 120,
                child: IgnorePointer(
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                child: Column(
                  children: [
                    _buildDeckHeader(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildDeckCanvas(profile)),
                  ],
                ),
              ),
            ],
          );
        },
        error: (error, stack) => const EmptyState(
          title: 'Something went wrong',
          subtitle: 'Please try again in a moment.',
          icon: Icons.error_outline,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildDeck() {
    if (_queue.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cards = _queue.take(3).toList();
    final topProfile = cards.first;
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * 0.18;
    final likeOpacity = (_dragOffset.dx / swipeThreshold).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / swipeThreshold).clamp(0.0, 1.0);
    final glowColor = _dragOffset.dx >= 0
        ? Colors.greenAccent
        : Colors.redAccent;
    final glowStrength = (_dragOffset.dx.abs() / swipeThreshold).clamp(
      0.0,
      1.0,
    );
    final dragFactor = (_dragOffset.dx.abs() / swipeThreshold).clamp(0.0, 1.0);
    final cardRadius = BorderRadius.circular(34);

    return Stack(
      children: [
        for (int index = cards.length - 1; index >= 0; index--)
          Positioned.fill(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.only(
                top: 9.0 * index - (index == 1 ? dragFactor * 6 : 0),
                left: index * 2 - (index == 1 ? dragFactor * 1.5 : 0),
                right: index * 2 - (index == 1 ? dragFactor * 1.5 : 0),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                scale:
                    1 - (index * 0.03) + (index == 1 ? dragFactor * 0.016 : 0),
                child: index == 0
                    ? Transform.translate(
                        offset: _dragOffset,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateZ(_dragRotation),
                          child: GestureDetector(
                            onPanStart: (_) {
                              if (_isAnimating) return;
                              _swipeController.stop();
                            },
                            onPanUpdate: (details) {
                              if (_isAnimating) return;
                              setState(() {
                                _dragOffset += details.delta;
                                _dragOffset = Offset(
                                  _dragOffset.dx,
                                  _dragOffset.dy.clamp(-120.0, 120.0),
                                );
                                _dragRotation =
                                    (_dragOffset.dx / screenWidth) * 0.14;
                              });
                            },
                            onPanEnd: (details) =>
                                _handlePanEnd(topProfile, details),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: cardRadius,
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary.withOpacity(
                                          theme.brightness == Brightness.dark
                                              ? 0.28
                                              : 0.16,
                                        ),
                                        theme.colorScheme.secondary.withOpacity(
                                          theme.brightness == Brightness.dark
                                              ? 0.2
                                              : 0.14,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.26),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.16),
                                        blurRadius: 24,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 14),
                                      ),
                                      if (glowStrength > 0)
                                        BoxShadow(
                                          color: glowColor.withOpacity(
                                            0.3 * glowStrength,
                                          ),
                                          blurRadius: 32,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 10),
                                        ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      ProfileCard(
                                        profile: cards[index],
                                        onTap: () => _openDetails(cards[index]),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 120,
                                            ),
                                            opacity: glowStrength * 0.24,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: cardRadius,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    glowColor.withOpacity(0.16),
                                                    Colors.transparent,
                                                  ],
                                                  begin: _dragOffset.dx >= 0
                                                      ? Alignment.centerLeft
                                                      : Alignment.centerRight,
                                                  end: _dragOffset.dx >= 0
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 24,
                                  left: 20,
                                  child: Opacity(
                                    opacity: likeOpacity,
                                    child: _SwipeBadge(
                                      label: 'LIKE',
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 24,
                                  right: 20,
                                  child: Opacity(
                                    opacity: nopeOpacity,
                                    child: _SwipeBadge(
                                      label: 'NOPE',
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Opacity(
                        opacity: index == 1 ? 0.94 : 0.8,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: cardRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ProfileCard(profile: cards[index]),
                          ),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeckCanvas(UserProfile profile) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _buildDeck()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.58, 1],
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.primary.withValues(alpha: 0.24),
                      theme.colorScheme.primary.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.38),
                      blurRadius: 32,
                      spreadRadius: 4,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -48,
            child: _buildFloatingActions(profile),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _DeckActionButton(
          icon: Icons.close_rounded,
          label: 'Pass',
          color: const Color(0xFFFF8AD8),
          enabled: !_processing,
          onTap: () => _triggerSwipe(liked: false),
        ),
        _DeckActionButton(
          icon: Icons.info_outline_rounded,
          label: 'Info',
          color: const Color(0xFFF5C7FF),
          enabled: !_processing,
          onTap: () => _openDetails(profile),
        ),
        _DeckActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          color: const Color(0xFF7CC8FF),
          enabled: !_processing,
          onTap: () => _startChat(profile),
        ),
        _DeckActionButton(
          icon: Icons.favorite_rounded,
          label: 'Like',
          color: const Color(0xFF89F3AF),
          enabled: !_processing,
          prominent: true,
          onTap: () => _triggerSwipe(liked: true),
        ),
      ],
    );
  }

  Widget _buildDeckHeader() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface.withOpacity(
              theme.brightness == Brightness.dark ? 0.45 : 0.96,
            ),
            theme.colorScheme.surface.withOpacity(
              theme.brightness == Brightness.dark ? 0.24 : 0.84,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.92),
                  theme.colorScheme.secondary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_queue.length} profiles available around you',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withOpacity(0.12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.32),
              ),
            ),
            child: Text(
              _queue.length.toString().padLeft(2, '0'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePanEnd(
    UserProfile profile,
    DragEndDetails details,
  ) async {
    if (_isAnimating) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.18;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipe =
        _dragOffset.dx.abs() > threshold || velocity.abs() > 900;

    if (shouldSwipe) {
      final liked = velocity.abs() > 600 ? velocity > 0 : _dragOffset.dx > 0;
      await _animateSwipe(profile: profile, liked: liked, velocity: velocity);
    } else {
      await _animateBack();
    }
  }

  Future<void> _triggerSwipe({required bool liked}) async {
    if (_queue.isEmpty) return;
    await _animateSwipe(profile: _queue.first, liked: liked);
  }

  Future<void> _animateSwipe({
    required UserProfile profile,
    required bool liked,
    double velocity = 0,
  }) async {
    if (_isAnimating) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = liked ? screenWidth * 1.35 : -screenWidth * 1.35;
    final endOffset = Offset(targetX, _dragOffset.dy + (velocity * 0.02));
    _isAnimating = true;
    await _runAnimation(endOffset);
    if (!mounted) return;
    setState(() {
      if (_queue.isNotEmpty) {
        _swipedIds.add(_queue.first.id);
        _queue.removeAt(0);
      }
      _dragOffset = Offset.zero;
      _dragRotation = 0;
    });
    _isAnimating = false;
    await _processSwipe(profile: profile, liked: liked);
  }

  Future<void> _animateBack() async {
    if (_isAnimating) return;
    _isAnimating = true;
    await _runAnimation(Offset.zero, curve: Curves.elasticOut);
    if (!mounted) return;
    setState(() {
      _dragOffset = Offset.zero;
      _dragRotation = 0;
    });
    _isAnimating = false;
  }

  Future<void> _runAnimation(
    Offset target, {
    Curve curve = Curves.easeOutCubic,
  }) async {
    final rotationTarget = target.dx == 0 ? 0.0 : (target.dx.sign * 0.15);
    _swipeOffsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _swipeController, curve: curve));
    _swipeRotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: rotationTarget,
    ).animate(CurvedAnimation(parent: _swipeController, curve: curve));
    await _swipeController.forward(from: 0);
  }

  void _openDetails(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(profile: profile),
    );
  }

  Future<void> _startChat(UserProfile profile) async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;

    final conversationId = await ref
        .read(chatServiceProvider)
        .createOrGetConversation(currentUid: auth.uid, otherUid: profile.id);

    if (!mounted) return;
    context.push('/chat/$conversationId', extra: profile.id);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text('Age range', style: Theme.of(context).textTheme.bodyMedium),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 60,
              divisions: 42,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (values) => setState(() => _ageRange = values),
            ),
            const SizedBox(height: 12),
            Text('Max distance: ${_maxDistance.round()} km'),
            Slider(
              value: _maxDistance,
              min: 5,
              max: 100,
              divisions: 19,
              label: '${_maxDistance.round()} km',
              onChanged: (value) => setState(() => _maxDistance = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _queue.clear();
                  ref.invalidate(discoverProfilesProvider);
                  Navigator.pop(context);
                },
                child: const Text('Apply filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBadge extends StatelessWidget {
  const _SwipeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _DeckActionButton extends StatelessWidget {
  const _DeckActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final buttonSize = prominent ? 62.0 : 54.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1 : 0.55,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: enabled ? onTap : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.38),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(prominent ? 0.45 : 0.28),
                    blurRadius: prominent ? 20 : 12,
                    spreadRadius: prominent ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.34),
                  width: prominent ? 1.4 : 1,
                ),
              ),
              child: Icon(icon, size: prominent ? 30 : 24, color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
