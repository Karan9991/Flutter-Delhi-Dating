import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({super.key, required this.profile, this.onTap});

  final UserProfile profile;
  final VoidCallback? onTap;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _index = 0;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final theme = Theme.of(context);
    final hasPhotos = profile.photoUrls.isNotEmpty;
    final indicatorCount = hasPhotos ? profile.photoUrls.length : 1;
    final safeIndex = hasPhotos
        ? _index.clamp(0, profile.photoUrls.length - 1)
        : 0;
    final compatibility = _compatibilityScore(profile);
    final topInterests = profile.interests.take(3).join(' • ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Positioned.fill(
            child: hasPhotos
                ? PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profile.photoUrls.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: profile.photoUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildPhotoFallback(theme),
                        errorWidget: (context, url, error) =>
                            _buildPhotoFallback(theme),
                      );
                    },
                  )
                : _buildPhotoFallback(theme),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _jumpTo(_index - 1),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _jumpTo(_index + 1),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 14,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(
                      indicatorCount,
                      (dotIndex) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 4,
                          margin: EdgeInsets.only(
                            right: dotIndex == indicatorCount - 1 ? 0 : 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: dotIndex == safeIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.onTap != null) ...[
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: widget.onTap,
                      child: Ink(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 56,
            left: 14,
            right: 14,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TopPill(
                  icon: Icons.auto_awesome_rounded,
                  text: '$compatibility% vibe match',
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.55, 0.77, 1],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.74),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${profile.displayName}, ${profile.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Delhi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (topInterests.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    topInterests,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFallback(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.22),
            theme.colorScheme.secondary.withValues(alpha: 0.18),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 42, color: Colors.white70),
      ),
    );
  }

  int _compatibilityScore(UserProfile profile) {
    if (profile.id.isEmpty) return 80;
    final checksum = profile.id.codeUnits.fold<int>(
      0,
      (sum, char) => sum + char,
    );
    return 74 + (checksum % 22);
  }

  void _jumpTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.profile.photoUrls.length) return;
    _controller.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
