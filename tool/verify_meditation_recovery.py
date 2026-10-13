#!/usr/bin/env python3
"""Execute unchanged service logic with fake platform adapters (not Flutter UI).
Usage: python3 tool/verify_meditation_recovery.py --dart /path/to/dart
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--dart', default='dart')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
files = [
    'lib/models/meditation_completion_record.dart',
    'lib/models/meditation_check_in_record.dart',
    'lib/data/meditation_media_data.dart',
    'lib/services/meditation_completion_journal.dart',
    'lib/services/meditation_completion_service.dart',
    'lib/services/meditation_course_store.dart',
    'lib/services/meditation_check_in_store.dart',
    'lib/services/meditation_library_store.dart',
]
stubs = r'''
import 'dart:convert';
class ChangeNotifier {void notifyListeners() {}}
class ValueNotifier<T> {T value; ValueNotifier(this.value);}
class SharedPreferences {
  static final instance = SharedPreferences();
  static final data = <String,dynamic>{};
  static final failKeys = <String>{};
  static Future<SharedPreferences> getInstance() async => instance;
  String? getString(String key) => data[key] as String?;
  List<String>? getStringList(String key) => (data[key] as List?)?.cast<String>();
  Future<void> reload() async {}
  Future<bool> setString(String key,String value) async {if(failKeys.contains(key)) return false; data[key]=value; return true;}
  Future<bool> setStringList(String key,List<String> value) async {data[key]=List.of(value);return true;}
  Future<bool> remove(String key) async {data.remove(key);return true;}
}
class Box {
  final data=<dynamic,dynamic>{}; bool failWrite=false, failDelete=false;
  Iterable<dynamic> get keys=>data.keys;
  bool containsKey(dynamic key)=>data.containsKey(key);
  dynamic get(dynamic key)=>data[key];
  Future<void> put(dynamic key,dynamic value) async {
    if(failWrite) throw StateError('disk-write');
    data[key]=jsonDecode(jsonEncode(value));
  }
  Future<void> delete(dynamic key) async {if(failDelete) throw StateError('delete');data.remove(key);}
  Future<void> flush() async {}
}
class HiveEncryption {
  static final boxes=<String,Box>{};
  static Future<Box> openBox(String name) async=>boxes.putIfAbsent(name,Box.new);
}
class MongiGardenStore {
  static final instance=MongiGardenStore();
  final days=<String>{}; bool fail=false; int get tokens=>days.length;
  Future<void> claimCompletedCare({DateTime? now,bool meditation=false}) async {
    if(fail) throw StateError('garden');
    days.add('${now!.year}-${now.month}-${now.day}');
  }
}
'''
contract = r'''
import 'dart:async';
import 'stubs.dart';
import 'lib/services/meditation_completion_service.dart';
import 'lib/services/meditation_completion_journal.dart';
import 'lib/services/meditation_course_store.dart';
import 'lib/services/meditation_library_store.dart';
import 'lib/models/meditation_completion_record.dart';
int checks=0;
void check(bool v,String label){if(!v)throw StateError(label);checks++;}
Future<void> main() async {
 final course=MeditationCourseStore.instance;
 final journal=MeditationCompletionJournal.instance;
 final box=await HiveEncryption.openBox(MeditationCompletionJournal.boxName);
 final garden=MongiGardenStore.instance;
 await course.activate('first7'); await course.begin('forestRest');
 SharedPreferences.failKeys.add('meditation.courses');
 final failed=MeditationCompletionService();
 await failed.complete(guideKey:'forestRest');
 check(failed.saveState.value==MeditationSaveState.waiting,'durably stored but not applied is visible');
 check((await journal.load()).length==1,'failed course commit leaves durable event');
 final event=(await journal.load()).single;
 check(course.step(meditationCourses.first)==0,'failed progress not reported as saved');
 SharedPreferences.failKeys.clear();
 await course.reload();
 final afterRestart=MeditationCompletionService();await afterRestart.retry();
 check(course.step(meditationCourses.first)==1,'restart recovers course from journal');
 check(garden.tokens==1,'restart applies care');
 check((await journal.load()).isEmpty,'successful effects acknowledge journal');
 await journal.save(event);box.failDelete=true;
 await afterRestart.retry();
 check(afterRestart.saveState.value==MeditationSaveState.waiting,'acknowledgement failure remains visible');
 check((await journal.load()).length==1,'acknowledgement failure retains replay event');
 box.failDelete=false;await MeditationCompletionService().retry();
 check(course.step(meditationCourses.first)==1 && garden.tokens==1,'post-commit restart cannot advance or grant twice');
 check((await journal.load()).isEmpty,'post-commit replay is removed');
 box.failWrite=true;
 final unsaved=MeditationCompletionService();await unsaved.complete(guideKey:'forestRest');
 check(unsaved.saveState.value==MeditationSaveState.unsaved,'journal failure distinguishes unsaved completion');
 var blocked=false;try{await unsaved.prepareForBackup();}catch(_){blocked=true;}
 check(blocked,'backup cannot claim completeness while completion is unsaved');
 box.failWrite=false;await unsaved.retry();
 check(unsaved.saveState.value==MeditationSaveState.idle && garden.tokens==1,'in-process journal retry retains daily idempotence');
 final old=DateTime(2025,1,2,23,59);
 await journal.save(MeditationCompletionRecord(id:'old-day',completedAt:old,guide:'forestRest',reward:true));
 garden.fail=true;await afterRestart.retry();
 check((await journal.load()).length==1,'garden write failure retains event');
 garden.fail=false;await MeditationCompletionService().retry();
 check(garden.days.contains('2025-1-2'),'late replay uses actual completion date');
 final entered=Completer<void>(), release=Completer<void>();
 final locked=MeditationCompletionService();
 final backup=locked.consistentRead(() async {entered.complete();await release.future;return 'snapshot';});
 await entered.future;
 var completionFinished=false;
 final duringBackup=locked.complete(guideKey:'forestRest').then((_) {completionFinished=true;});
 await Future<void>.delayed(Duration.zero);
 check(!completionFinished && (await journal.load()).isEmpty,'completion cannot partially apply inside a backup read');
 release.complete();await backup;await duringBackup;
 check(completionFinished && locked.saveState.value==MeditationSaveState.idle,'completion proceeds after snapshot unlock');
 final library=MeditationLibraryStore();
 final first=await library.checkIn('same-session','forestRest','better');
 final duplicate=await library.checkIn('same-session','forestRest','worse');
 check(first.feeling=='better' && duplicate.feeling=='better','duplicate save returns actual stored answer');
 final reentered=MeditationLibraryStore();
 check((await reentered.findCheckIn('same-session'))!.feeling=='better','recreated view can load stored answer');
 for(var i=0;i<91;i++){await library.checkIn('later-$i','forestRest','same');}
 check(library.checkIns.length==90,'history display remains bounded');
 check((await library.findCheckIn('same-session'))!.feeling=='better','session lookup still finds feedback older than display window');
 print('PASS: $checks meditation journal, recovery, replay and feedback checks (fake platform adapters; no Flutter UI).');
}
'''
with tempfile.TemporaryDirectory(prefix='meditation-recovery-contract-') as temp:
    dest = Path(temp)
    for relative in files:
        target = dest/relative
        target.parent.mkdir(parents=True, exist_ok=True)
        source = (root/relative).read_text()
        lines = []
        added = False
        for line in source.splitlines():
            external = line.startswith("import 'package:") or line in [
                "import 'hive_encryption.dart';",
                "import '../mongi/integration/mongi_garden_store.dart';",
            ]
            if external:
                if not added:
                    lines.append("import '../../stubs.dart';")
                    added = True
            else:
                lines.append(line)
        target.write_text('\n'.join(lines)+'\n')
    (dest/'stubs.dart').write_text(stubs)
    (dest/'contract.dart').write_text(contract)
    subprocess.run([args.dart, 'analyze', str(dest)], check=True)
    subprocess.run([args.dart, 'run', str(dest/'contract.dart')], check=True)
