import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/subscriber_journeys.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';

class SubscriberJourneysScreen extends StatefulWidget {
  const SubscriberJourneysScreen({super.key});
  @override
  State<SubscriberJourneysScreen> createState()=>_SubscriberJourneysScreenState();
}
class _SubscriberJourneysScreenState extends State<SubscriberJourneysScreen> {
  bool _premium=false;
  final Set<String> _done={};
  @override
  void initState(){super.initState();_load();}
  Future<void> _load() async {
    final premium=await SubscriptionService().isPremium();
    final prefs=await SharedPreferences.getInstance();
    if(mounted)setState((){_premium=premium;_done.clear();_done.addAll(prefs.getStringList('local_user_journey_done')??[]);});
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('고양이와 함께하는 여정')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      const Text('준비된 3개 주제, 각 4개의 이야기예요. 주 1편씩 또는 편한 속도로 만나보세요. 쉬었던 날의 벌점은 없어요.'),
      for(final journey in subscriberJourneys) Card(child:ExpansionTile(title:Text(journey.title),children:[
        for(var i=0;i<journey.weeks.length;i++) Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text('${i+1}번째 이야기'),
          if(_premium || i==0) ...[
            Text(journey.weeks[i].story),const SizedBox(height:10),
            Text(journey.weeks[i].question),const SizedBox(height:10),
            Text(journey.weeks[i].action),
            CheckboxListTile(title:const Text('이 이야기를 만나봤어요'),value:_done.contains('${journey.id}_$i'),onChanged:(value)async{
              final key='${journey.id}_$i';setState((){if(value==true){_done.add(key);}else{_done.remove(key);}});
              final prefs=await SharedPreferences.getInstance();await prefs.setStringList('local_user_journey_done',_done.toList());
            }),
          ] else TextButton(onPressed:()async{await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const PremiumScreen()));await _load();},child:const Text('정원 플러스로 이어 읽기')),
        ])),
      ])),
    ]),
  );
}
