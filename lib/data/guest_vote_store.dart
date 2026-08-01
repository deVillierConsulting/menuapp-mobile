import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kVotesKey = 'guest_votes';
const _kOnboardingDoneKey = 'onboarding_complete';

/// A recipe ID + which way the user swiped during the unauthenticated
/// onboarding session. Persisted locally in SharedPreferences so the votes
/// survive the app being backgrounded before sign-in.
class GuestVote {
  final int recipeId;
  final String voteValue; // 'approve' | 'veto'

  const GuestVote({required this.recipeId, required this.voteValue});

  Map<String, dynamic> toJson() =>
      {'recipe_id': recipeId, 'vote_value': voteValue};

  factory GuestVote.fromJson(Map<String, dynamic> json) => GuestVote(
        recipeId: json['recipe_id'] as int,
        voteValue: json['vote_value'] as String,
      );
}

/// Thin SharedPreferences wrapper for guest session state.
///
/// All methods are static to keep call sites simple — callers don't need to
/// hold an instance, they just import the class.
class GuestVoteStore {
  GuestVoteStore._();

  // Set to true in-memory as soon as markOnboardingComplete is called so the
  // router can check it synchronously without re-reading SharedPreferences.
  static bool _completedThisSession = false;
  static bool get completedThisSession => _completedThisSession;

  static Future<List<GuestVote>> loadVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVotesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GuestVote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveVotes(List<GuestVote> votes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVotesKey, jsonEncode(votes.map((v) => v.toJson()).toList()));
  }

  static Future<void> addVote(GuestVote vote) async {
    final existing = await loadVotes();
    // Replace any existing vote for the same recipe.
    final updated = [
      ...existing.where((v) => v.recipeId != vote.recipeId),
      vote,
    ];
    await saveVotes(updated);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVotesKey);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDoneKey) ?? false;
  }

  static Future<void> markOnboardingComplete() async {
    _completedThisSession = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);
  }
}
