import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message.dart';
import '../../models/user_profile.dart';
import '../../providers.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/profile_detail_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
  });

  final String matchId;
  final String otherUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastRenderedMessageId;
  String? _lastReadSyncIncomingMessageId;
  bool _didInitialScroll = false;
  bool _presenceActive = false;
  bool _isSyncingReadReceipts = false;

  @override
  void initState() {
    super.initState();
    _activatePresence();
  }

  @override
  void activate() {
    super.activate();
    _activatePresence();
  }

  @override
  void deactivate() {
    _clearPresence();
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId == widget.matchId) return;
    _didInitialScroll = false;
    _lastRenderedMessageId = null;
    _lastReadSyncIncomingMessageId = null;
    _activatePresence();
  }

  @override
  void dispose() {
    _clearPresence();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;
    final text = _controller.text;
    _controller.clear();
    await ref
        .read(chatServiceProvider)
        .sendMessage(matchId: widget.matchId, senderId: auth.uid, text: text);
  }

  Future<void> _openProfile() async {
    if (widget.otherUserId.isEmpty) return;
    final profile = await ref
        .read(firestoreServiceProvider)
        .getProfile(widget.otherUserId);
    if (!mounted || profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(profile: profile),
    );
  }

  Future<void> _confirmUnmatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch?'),
        content: const Text('This will remove the match and chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(chatServiceProvider).unmatch(widget.matchId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDeleteChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'This will permanently delete all messages in this chat.',
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
    await ref.read(chatServiceProvider).deleteChat(widget.matchId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).value;
    final readReceiptsEnabled = ref
        .watch(userSettingsProvider)
        .maybeWhen(
          data: (settings) => settings.messageReadReceipts,
          orElse: () => true,
        );
    final messagesStream = ref
        .watch(chatServiceProvider)
        .messagesStream(widget.matchId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<UserProfile?>(
          future: widget.otherUserId.isEmpty
              ? Future.value(null)
              : ref
                    .read(firestoreServiceProvider)
                    .getProfile(widget.otherUserId),
          builder: (context, snapshot) {
            final name = snapshot.data?.displayName ?? 'Chat';
            return Text(name);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _openProfile();
              }
              if (value == 'delete_chat') {
                _confirmDeleteChat();
              }
              if (value == 'unmatch') {
                _confirmUnmatch();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('View profile'),
              ),
              const PopupMenuItem(
                value: 'delete_chat',
                child: Text('Delete chat'),
              ),
              const PopupMenuItem(value: 'unmatch', child: Text('Unmatch')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Start the conversation.'));
                }
                _maybeAutoScroll(messages: messages, myUid: auth?.uid);
                _maybeSyncReadReceipts(
                  messages: messages,
                  myUid: auth?.uid,
                  readReceiptsEnabled: readReceiptsEnabled,
                );
                final lastOutgoingIndex = _lastOutgoingIndex(
                  messages,
                  auth?.uid,
                );
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == auth?.uid;
                    final isLastOutgoing = index == lastOutgoingIndex;
                    final showReceipt =
                        isMe && isLastOutgoing && widget.otherUserId.isNotEmpty;
                    return ChatBubble(
                      message: message.text,
                      isMe: isMe,
                      timestamp: message.sentAt,
                      receiptText: showReceipt
                          ? (message.isReadBy(widget.otherUserId)
                                ? 'Seen'
                                : 'Sent')
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _maybeAutoScroll({
    required List<ChatMessage> messages,
    required String? myUid,
  }) {
    if (messages.isEmpty) return;

    final latestId = messages.last.id;
    final hasNewMessage = latestId != _lastRenderedMessageId;
    final isInitial = !_didInitialScroll;

    if (isInitial) {
      _didInitialScroll = true;
      _lastRenderedMessageId = latestId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
      return;
    }

    if (!hasNewMessage) return;
    _lastRenderedMessageId = latestId;

    final latest = messages.last;
    final fromMe = latest.senderId == myUid;
    final nearBottom =
        !_scrollController.hasClients ||
        (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels) <
            140;
    if (!fromMe && !nearBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  int _lastOutgoingIndex(List<ChatMessage> messages, String? myUid) {
    if (myUid == null) return -1;
    for (var index = messages.length - 1; index >= 0; index--) {
      if (messages[index].senderId == myUid) {
        return index;
      }
    }
    return -1;
  }

  void _maybeSyncReadReceipts({
    required List<ChatMessage> messages,
    required String? myUid,
    required bool readReceiptsEnabled,
  }) {
    if (!readReceiptsEnabled || myUid == null || messages.isEmpty) return;

    final unreadIncoming = messages
        .where(
          (message) => message.senderId != myUid && !message.isReadBy(myUid),
        )
        .toList(growable: false);
    if (unreadIncoming.isEmpty) return;

    final latestIncomingId = unreadIncoming.last.id;
    if (_isSyncingReadReceipts) return;
    if (_lastReadSyncIncomingMessageId == latestIncomingId) return;

    _lastReadSyncIncomingMessageId = latestIncomingId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _isSyncingReadReceipts = true;
      try {
        await ref
            .read(chatServiceProvider)
            .markMessagesRead(matchId: widget.matchId, readerUid: myUid);
      } catch (_) {
        _lastReadSyncIncomingMessageId = null;
      } finally {
        _isSyncingReadReceipts = false;
      }
    });
  }

  void _activatePresence() {
    ref.read(chatPresenceServiceProvider).setActiveMatch(widget.matchId);
    _presenceActive = true;
  }

  void _clearPresence() {
    if (!_presenceActive) return;
    ref
        .read(chatPresenceServiceProvider)
        .clearActiveMatch(onlyIfMatchId: widget.matchId);
    _presenceActive = false;
  }
}
