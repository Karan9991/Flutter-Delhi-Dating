import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/like_item.dart';
import '../../models/match_item.dart';
import '../../providers.dart';
import '../../widgets/empty_state.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesState = ref.watch(matchesProvider);
    final likesState = ref.watch(incomingLikesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'New likes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            child: likesState.when(
              data: (likes) {
                if (likes.isEmpty) {
                  return _likesPlaceholder(context);
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: likes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _LikeCard(item: likes[index]),
                );
              },
              error: (error, stackTrace) =>
                  _likesPlaceholder(context, text: 'Could not load likes.'),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Messages',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          matchesState.when(
            data: (matches) {
              if (matches.isEmpty) {
                return const SizedBox(
                  height: 260,
                  child: EmptyState(
                    title: 'No conversations yet',
                    subtitle:
                        'Start swiping or message someone from New likes.',
                    icon: Icons.chat_bubble_outline,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _MatchTile(match: matches[index]),
              );
            },
            error: (error, stackTrace) => const SizedBox(
              height: 260,
              child: EmptyState(
                title: 'Could not load matches',
                subtitle: 'Please try again in a bit.',
                icon: Icons.error_outline,
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _likesPlaceholder(BuildContext context, {String? text}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        text ?? 'No new likes yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

class _LikeCard extends ConsumerWidget {
  const _LikeCard({required this.item});

  final LikeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final likedAt = item.likedAt == null
        ? null
        : DateFormat('MMM d').format(item.likedAt!);
    final hasPhoto = item.user.photoUrls.isNotEmpty;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: hasPhoto
                    ? CachedNetworkImageProvider(item.user.photoUrls.first)
                    : null,
                child: hasPhoto ? null : const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (likedAt != null)
                Text(
                  likedAt,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.user.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _message(context, ref),
                  child: const Text('Message'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _likeBack(ref),
                  child: const Text('Like back'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _likeBack(WidgetRef ref) async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;
    await ref
        .read(matchingServiceProvider)
        .likeUser(currentUid: auth.uid, otherUid: item.user.id);
  }

  Future<void> _message(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;

    final conversationId = await ref
        .read(chatServiceProvider)
        .createOrGetConversation(currentUid: auth.uid, otherUid: item.user.id);

    if (!context.mounted) return;
    context.push('/chat/$conversationId', extra: item.user.id);
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastMessageTime = match.lastMessageAt == null
        ? null
        : DateFormat('MMM d').format(match.lastMessageAt!);

    return InkWell(
      onTap: () =>
          context.push('/chat/${match.matchId}', extra: match.otherUser.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: CachedNetworkImageProvider(
                match.otherUser.photoUrls.first,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.otherUser.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.lastMessage ?? 'Say hello!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageTime != null)
                  Text(
                    lastMessageTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.56),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete_chat') {
                      await _confirmDeleteChat(context, ref);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete_chat',
                      child: Text('Delete chat'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteChat(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'All messages in this conversation will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(chatServiceProvider).deleteChat(match.matchId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
  }
}
