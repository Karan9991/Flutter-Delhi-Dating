class UserSettings {
  const UserSettings({
    required this.pushNotifications,
    required this.messageNotifications,
    required this.matchNotifications,
    required this.likeNotifications,
    required this.messageReadReceipts,
    required this.showAge,
    required this.showDistance,
    required this.discoverable,
    required this.themeMode,
    required this.accentColorValue,
  });

  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const int defaultAccentColorValue = 0xFFFF00FF;

  final bool pushNotifications;
  final bool messageNotifications;
  final bool matchNotifications;
  final bool likeNotifications;
  final bool messageReadReceipts;
  final bool showAge;
  final bool showDistance;
  final bool discoverable;
  final String themeMode;
  final int accentColorValue;

  UserSettings copyWith({
    bool? pushNotifications,
    bool? messageNotifications,
    bool? matchNotifications,
    bool? likeNotifications,
    bool? messageReadReceipts,
    bool? showAge,
    bool? showDistance,
    bool? discoverable,
    String? themeMode,
    int? accentColorValue,
  }) {
    return UserSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      matchNotifications: matchNotifications ?? this.matchNotifications,
      likeNotifications: likeNotifications ?? this.likeNotifications,
      messageReadReceipts: messageReadReceipts ?? this.messageReadReceipts,
      showAge: showAge ?? this.showAge,
      showDistance: showDistance ?? this.showDistance,
      discoverable: discoverable ?? this.discoverable,
      themeMode: themeMode ?? this.themeMode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'messageNotifications': messageNotifications,
      'matchNotifications': matchNotifications,
      'likeNotifications': likeNotifications,
      'messageReadReceipts': messageReadReceipts,
      'showAge': showAge,
      'showDistance': showDistance,
      'discoverable': discoverable,
      'themeMode': themeMode,
      'accentColorValue': accentColorValue,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    final mode = map?['themeMode'] as String?;
    return UserSettings(
      pushNotifications: map?['pushNotifications'] as bool? ?? true,
      messageNotifications: map?['messageNotifications'] as bool? ?? true,
      matchNotifications: map?['matchNotifications'] as bool? ?? true,
      likeNotifications: map?['likeNotifications'] as bool? ?? true,
      messageReadReceipts: map?['messageReadReceipts'] as bool? ?? true,
      showAge: map?['showAge'] as bool? ?? true,
      showDistance: map?['showDistance'] as bool? ?? true,
      discoverable: map?['discoverable'] as bool? ?? true,
      themeMode: mode == themeDark ? themeDark : themeLight,
      accentColorValue:
          (map?['accentColorValue'] is num)
          ? (map?['accentColorValue'] as num).toInt()
          : defaultAccentColorValue,
    );
  }
}
