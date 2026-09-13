import 'package:flutter/material.dart';
import '../models/reply_style.dart';
class ReplyStylePicker extends StatelessWidget {
  final ReplyStyle value;
  final ValueChanged<ReplyStyle> onChanged;
  final bool enabled;
  const ReplyStylePicker({super.key,required this.value,required this.onChanged,this.enabled=true});
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('어떤 답장을 받고 싶나요? (선택)'),
    Wrap(spacing:6,children:[for(final style in ReplyStyle.values) ChoiceChip(
      label:Text(style.label),selected:value==style,onSelected:enabled?(_)=>onChanged(style):null)]),
    const Text('고양이 답장은 편지 속 표현과 준비된 문장으로 기기에서 만들어요. 복잡한 사연을 모두 이해하지는 못해요.',style:TextStyle(fontSize:12)),
  ]);
}
