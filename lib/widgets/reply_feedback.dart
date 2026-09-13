import 'package:flutter/material.dart';
import '../services/personal_reply_service.dart';
class ReplyFeedback extends StatefulWidget {
  final String replyId;
  const ReplyFeedback({super.key,required this.replyId});
  @override
  State<ReplyFeedback> createState()=>_ReplyFeedbackState();
}
class _ReplyFeedbackState extends State<ReplyFeedback> {
  String? _value;
  bool _busy=true;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load()async{
    try{final value=await PersonalReplyService.feedback(widget.replyId);if(mounted)setState(()=>_value=value);}
    catch(_){/* Feedback failure never hides the letter. */}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _save(String value)async{
    setState(()=>_busy=true);
    try{
      final next=_value==value?null:value;
      await PersonalReplyService.setFeedback(widget.replyId,next);
      if(mounted)setState(()=>_value=next);
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('평가를 저장하지 못했어요. 다시 시도해 주세요.')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('이번 답장은 어땠나요? (선택)'),
    Wrap(spacing:4,children:[for(final item in const {'matched':'잘 맞아요','off_topic':'조금 엇나갔어요','repeated':'전에 본 느낌이에요'}.entries)
      FilterChip(label:Text(item.value),selected:_value==item.key,onSelected:_busy?null:(_)=>_save(item.key))]),
    const Text('평가는 이 기기에 저장돼요. 반복 평가는 이후 문장 선택에 참고해요. 최근 답장 20개 중 같은 주제에서 엇나갔다는 평가가 2번 쌓이면 이후에는 그 주제를 단정하는 표현을 줄여요. 이미 받은 편지는 바뀌지 않아요.',style:TextStyle(fontSize:11)),
  ]));
}
