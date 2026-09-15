import 'dart:convert';

/// Only local play/diary state is portable. Purchase entitlements are excluded.
class MongiBackupSchema {
  static const types = <String, String>{
    'garden_progress': 'num',
    'total_fed_count': 'int',
    'today_fed_count': 'int',
    'last_fed_date': 'string',
    'streak_days': 'int',
    'flower_counts': 'map',
    'diary_entries': 'list',
    'premium_frame_interest_count': 'int',
    'has_seen_onboarding': 'bool',
    'notif_enabled': 'bool',
    'notif_hour': 'int',
    'notif_minute': 'int',
    'language_code': 'string',
    'has_bloomed_once': 'bool',
    'garden_score': 'int',
    'tree_milestone_claimed_stage': 'int',
    'last_checkin_date': 'string',
    'last_checkin_emotion': 'string',
    'checkin_streak_days': 'int',
    'best_checkin_streak_days': 'int',
    'best_endless_count': 'int',
    'best_endless_seconds': 'int',
    'has_seen_growth_milestone': 'bool',
    'last_weekly_report_date': 'string',
    'golden_frame_emotions': 'list',
    'transcended_emotions': 'list',
    'last_easter_egg_date': 'string',
    'last_easter_egg_line': 'int',
    'last_mongi_letter_date': 'string',
    'has_unread_mongi_letter': 'bool',
    'safety_plan_data': 'map',
    'star_shard': 'int',
    'power_charm_count': 'int',
    'mongi_care_counts': 'map',
    'owned_costumes': 'list',
    'equipped_costume': 'string',
    'gacha_total_pulls': 'int',
    'season_pass_start_at': 'int',
    'season_pass_number': 'int',
    'season_pass_xp': 'int',
    'season_pass_claimed_free': 'list',
    'season_pass_claimed_premium': 'list',
    'daily_mission_date': 'string',
    'daily_mission_progress': 'map',
    'daily_mission_claimed': 'list',
    'daily_mission_all_clear_claimed': 'bool',
    'mind_challenge_active_id': 'string',
    'mind_challenge_start_date': 'string',
    'mind_challenge_checked_dates': 'list',
    'mind_challenge_completed_ids': 'list',
    'last_cheer_sent_date': 'string',
    'last_cheer_received_date': 'string',
    'today_cheer_received_index': 'int',
    'cheer_sent_total_count': 'int',
    'last_breathing_reward_date': 'string',
    'breathing_library_total_completions': 'int',
    'ai_reflection_opt_in': 'bool',
    'gratitude_log_entries': 'list',
  };
  static bool allows(Object key) => types.containsKey(key);
  static void validate(Object key, dynamic value) {
    final kind = types[key];
    final valid = switch (kind) {
      'string' => value == null || value is String,
      'bool' => value is bool,
      'int' => value is int,
      'num' => value is num && value.isFinite,
      'list' => value is List,
      'map' => value is Map,
      _ => false,
    };
    if (!valid || jsonEncode(value).length > 2000000) {
      throw const FormatException('몽이 백업 기록이 올바르지 않아요.');
    }
    if (value is int && value < -1) throw const FormatException('잘못된 몽이 수치');
    if (value is List) {
      if (key == 'diary_entries' || key == 'gratitude_log_entries') {
        if (value.any((row) => row is! Map || row['date'] is! String)) throw const FormatException('잘못된 몽이 일기');
      } else if (key == 'season_pass_claimed_free' || key == 'season_pass_claimed_premium') {
        if (value.any((row) => row is! int || row < 1)) throw const FormatException('잘못된 시즌 기록');
      } else if (value.any((row) => row is! String)) {
        throw const FormatException('잘못된 몽이 목록');
      }
    }
    if (value is Map && value.entries.any((entry) => entry.key is! String ||
        (key == 'safety_plan_data' ? entry.value is! String : entry.value is! int || (entry.value as int) < 0))) {
      throw const FormatException('잘못된 몽이 기록');
    }
  }
}
