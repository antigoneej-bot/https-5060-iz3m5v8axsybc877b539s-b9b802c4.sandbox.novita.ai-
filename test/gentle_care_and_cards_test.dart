import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/consciousness_insight_service.dart';
import 'package:flutter_app/services/letter_reply_insight_service.dart';
import 'package:flutter_app/services/relationship_story_service.dart';
import 'package:flutter_app/models/letter_tags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('test_gentle');
  });
  test('one task completes daily care; further tasks do not repeat bonus', () async {
    final first = await CatCareService.completeTask(CareTask.feed, isPremium: false);
    expect(first.allDoneToday, isTrue);
    expect(first.temperature, 1);
    for (final task in CareTask.values) {
      final next = await CatCareService.completeTask(task, isPremium: false);
      expect(next.temperature, 1);
    }
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('test_gentle_care_total_full_care_days'), 1);
  });
  test('any task can be the first daily care action', () async {
    for (final task in CareTask.values) {
      SharedPreferences.setMockInitialValues({});
      final state = await CatCareService.completeTask(task, isPremium: false);
      expect(state.allDoneToday, isTrue);
      expect(state.temperature, 1);
    }
  });
  test('random card comparison never becomes a diagnosis', () {
    expect(ConsciousnessInsightService.build(consciousCatId: null, unconsciousCatId: 'sad'), isNull);
    for (final chosen in ['sad', 'angry', 'dreamy']) {
      for (final drawn in ['sad', 'angry', 'dreamy']) {
        final result = ConsciousnessInsightService.build(consciousCatId: chosen, unconsciousCatId: drawn)!;
        expect(result.stateDescription, contains('재미용'));
        expect(result.comfort, contains('그냥 넘겨도'));
        expect(result.stateDescription, isNot(contains('박사')));
      }
    }
  });
  test('every emotion has a reflective question', () {
    for (final emotion in EmotionTag.values) {
      expect(LetterReplyInsightService.build(emotion).stateDescription, endsWith('?'));
    }
  });
  test('relationship scenes are stable for a day and vary across days', () {
    for (final stage in IntimacyTag.values) {
      final date = DateTime(2026, 9, 12);
      expect(RelationshipStoryService.lineFor(stage, date), RelationshipStoryService.lineFor(stage, date));
      expect(RelationshipStoryService.lineFor(stage, date), isNot(RelationshipStoryService.lineFor(stage, date.add(const Duration(days: 1)))));
    }
  });
}
