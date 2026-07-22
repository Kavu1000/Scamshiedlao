import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kSessionKey = 'scamshield_session_id';

/// Provides the singleton SessionService.
final sessionServiceProvider = Provider<SessionService>((ref) => SessionService());

/// Manages a persistent device-based session ID.
/// Replaces chrome.storage.local session management from background.js.
class SessionService {
  String? _cachedSessionId;

  /// Returns the existing session ID or generates a new UUID-based one.
  Future<String> getSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId!;

    final prefs = await SharedPreferences.getInstance();
    var sid = prefs.getString(_kSessionKey);
    if (sid == null || sid.isEmpty) {
      sid = 'session_${const Uuid().v4()}';
      await prefs.setString(_kSessionKey, sid);
    }
    _cachedSessionId = sid;
    return sid;
  }

  /// Clears and regenerates the session ID (e.g., on user request).
  Future<String> resetSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = 'session_${const Uuid().v4()}';
    await prefs.setString(_kSessionKey, sid);
    _cachedSessionId = sid;
    return sid;
  }
}
