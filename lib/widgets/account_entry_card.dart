import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../services/social_auth_service.dart';
import '../theme.dart';

/// The account entrance stays visible even before server setup is complete.
/// It is shared by My and the neighbor garden so nobody has to find backup
/// settings in order to sign in.
class AccountEntryCard extends StatefulWidget {
  const AccountEntryCard({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<AccountEntryCard> createState() => _AccountEntryCardState();
}

class _AccountEntryCardState extends State<AccountEntryCard> {
  StreamSubscription<User?>? _accountSubscription;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (SocialAuthService.firebaseReady) {
      _accountSubscription = FirebaseAuth.instance.userChanges().listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const AccountScreen()));
    if (!mounted) return;
    setState(() => _opening = false);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final user = SocialAuthService.currentUser;
    final signedIn = user != null;
    return Material(
      color: AppColors.catSageBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.sageLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('account-entry-card'),
        onTap: _opening ? null : _open,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                signedIn ? Icons.account_circle_outlined : Icons.login_rounded,
                color: AppColors.titlePastelGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signedIn ? '내 계정 관리' : '간편 로그인',
                      style: bodyFont(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titlePastelGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      signedIn
                          ? '로그인 정보 · 계정 확인 · 로그아웃'
                          : '구글 · 카카오 · 네이버 · 페이스북',
                      style: bodyFont(fontSize: 12, color: AppColors.ink),
                    ),
                    if (!signedIn) ...[
                      const SizedBox(height: 5),
                      Text(
                        '로그인하고 이웃의 정원에 응원을 건네요.',
                        style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.titlePastelGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
