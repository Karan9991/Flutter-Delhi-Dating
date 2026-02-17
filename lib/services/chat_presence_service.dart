import 'package:flutter/foundation.dart';

class ChatPresenceService extends ChangeNotifier {
  String? _activeMatchId;

  String? get activeMatchId => _activeMatchId;

  bool isViewingMatch(String? matchId) {
    if (matchId == null || matchId.isEmpty) return false;
    return _activeMatchId == matchId;
  }

  void setActiveMatch(String? matchId) {
    final normalized = (matchId == null || matchId.isEmpty) ? null : matchId;
    if (_activeMatchId == normalized) return;
    _activeMatchId = normalized;
    notifyListeners();
  }

  void clearActiveMatch({String? onlyIfMatchId}) {
    if (onlyIfMatchId != null &&
        onlyIfMatchId.isNotEmpty &&
        _activeMatchId != onlyIfMatchId) {
      return;
    }
    setActiveMatch(null);
  }
}
