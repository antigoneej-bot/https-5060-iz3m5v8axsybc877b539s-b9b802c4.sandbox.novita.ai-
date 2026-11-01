import 'package:flutter/material.dart';
import '../screens/terms_of_service_screen.dart';

final communityNavigatorKey = GlobalKey<NavigatorState>();
Future<bool> requestCommunityConsent() async {
  final context = communityNavigatorKey.currentContext;
  if (context == null) return false;
  return await showDialog<bool>(context: context, barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('이웃과 함께하는 약속'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('정원 별명과 공유 글은 다른 이용자에게 보여요. 괴롭힘·혐오·성적 콘텐츠·폭력 위협·스팸·사기·타인의 개인정보 공개를 금지합니다. 부적절한 내용은 신고·차단할 수 있고, 검토 후 공개 중단이나 공유 이용 제한이 적용될 수 있어요. 동의하지 않아도 개인 기록은 사용할 수 있어요.'),
        TextButton(onPressed: () => Navigator.of(dialogContext).push(MaterialPageRoute<void>(
          builder: (_) => const TermsOfServiceScreen())), child: const Text('이용약관 전체 읽기')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('나중에')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('동의하고 계속'))],
    )) ?? false;
}
