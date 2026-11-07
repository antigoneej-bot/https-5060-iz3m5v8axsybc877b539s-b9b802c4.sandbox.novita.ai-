import '../l10n/app_language.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/cloud_service.dart';
import '../services/social_auth_service.dart';
import '../theme.dart';
import 'data_safety_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// One account entry point. No password sign-up is offered to new users;
/// existing password accounts retain their identity, recovery and purchases.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.returnWhenReady = false});
  final bool returnWhenReady;

  static Future<bool> ensureSignedIn(BuildContext context) async {
    try {
      if (await SocialAuthService.isAccountReady()) return true;
    } catch (_) {
      // Let the account screen explain an expired/unavailable session.
    }
    if (!context.mounted) return false;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AccountScreen(returnWhenReady: true),
      ),
    );
    if (result != true) return false;
    try {
      return await SocialAuthService.isAccountReady();
    } catch (_) {
      return false;
    }
  }

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _ready = false;
  String _provider = tr("계정");
  String? _message;

  @override
  void initState() {
    super.initState();
    _readAccount();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _readAccount() async {
    try {
      final ready = await SocialAuthService.isAccountReady();
      final provider = await SocialAuthService.providerLabel();
      if (mounted)
        setState(() {
          _ready = ready;
          _provider = provider;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _ready = false;
          _message = tr("계정 상태를 확인하지 못했어요. 연결 후 다시 확인해 주세요.");
        });
    }
  }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        final message = SocialAuthService.messageFor(error);
        setState(() => _message = message);
        // The inline message may be above the current scroll position. Keep
        // failures visible even when a provider button is tapped lower down.
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        await _readAccount();
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _finishSignIn(bool signedIn) async {
    if (!signedIn) {
      if (mounted) setState(() => _message = tr("로그인을 취소했어요."));
      return;
    }
    _password.clear();
    final ready = await SocialAuthService.isAccountReady(forceRefresh: true);
    if (!ready) {
      if (mounted)
        setState(() => _message = tr("기존 이메일 계정으로 로그인했어요. 받은 인증 메일을 확인해 주세요."));
      return;
    }
    var message = tr("로그인했어요. 이 기기의 기록은 그대로 유지돼요.");
    if (CloudService.enabled) {
      try {
        await CloudService.refreshEntitlement();
      } catch (_) {
        message = tr("로그인했어요. 구독 상태는 연결 후 다시 확인해 주세요.");
      }
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
      _message = message;
    });
    if (widget.returnWhenReady) {
      // The caller resumes the selected purchase; this screen never starts one.
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _legacyLogin() async {
    if (!SocialAuthService.firebaseReady) {
      throw const SocialAuthException('not-configured');
    }
    if (SocialAuthService.signedIn) {
      throw const SocialAuthException('already-signed-in');
    }
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _message = tr("기존에 이용한 이메일과 비밀번호를 입력해 주세요."));
      return;
    }
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email.text.trim(),
      password: _password.text,
    );
    await _finishSignIn(true);
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _message = tr("비밀번호를 재설정할 이메일을 먼저 입력해 주세요."));
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _email.text.trim(),
    );
    if (mounted)
      setState(
        () => _message = tr("등록된 이메일이면 비밀번호 재설정 안내를 받을 수 있어요. 스팸함도 확인해 주세요."),
      );
  }

  Future<void> _verifyEmail() async {
    final user = SocialAuthService.currentUser;
    if (user == null) return;
    await user.reload();
    if (SocialAuthService.currentUser?.uid != user.uid) {
      throw const SocialAuthException('account-changed');
    }
    await SocialAuthService.currentUser!.getIdToken(true);
    if (await SocialAuthService.isAccountReady()) {
      await _finishSignIn(true);
    } else if (mounted) {
      setState(() => _message = tr("아직 이메일 인증 전이에요. 메일의 인증 링크를 눌러 주세요."));
    }
  }

  Future<void> _resendVerification() async {
    final user = SocialAuthService.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
    if (mounted)
      setState(() => _message = tr("인증 메일을 다시 보냈어요. 받은편지함과 스팸함을 확인해 주세요."));
  }

  Future<void> _signOut() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("로그아웃할까요?")),
        content: Text(
          tr(
            "이 기기의 기록과 정원은 남고 자동 백업은 꺼져요. 다른 로그인 방식은 별도 계정일 수 있으니, 구매할 때 사용한 계정을 기억해 주세요.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("취소")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr("로그아웃")),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await SocialAuthService.signOut();
    if (mounted)
      setState(() {
        _ready = false;
        _message = tr("로그아웃했어요. 이 기기의 기록은 그대로 남아 있어요.");
      });
  }

  Future<void> _linkGoogle() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("현재 계정에 Google 로그인을 연결할까요?")),
        content: Text(
          tr(
            "이메일 계정의 구매 내역과 계정 번호를 유지하며, 이후에는 선택한 Google 계정으로도 로그인해요. 다른 마음냥 계정에 이미 연결된 Google 계정은 합칠 수 없어요.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("취소")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr("연결하기")),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final linked = await SocialAuthService.linkGoogleToCurrentAccount();
    if (mounted)
      setState(
        () => _message = linked
            ? tr("현재 계정에 Google 로그인을 연결했어요.")
            : tr("연결을 취소했어요."),
      );
    if (linked && widget.returnWhenReady) await _finishSignIn(true);
  }

  Widget _providerButton(
    String label,
    Color background,
    Color foreground,
    Future<bool> Function() signIn,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            minimumSize: const Size.fromHeight(52),
            side: background == Colors.white
                ? const BorderSide(color: AppColors.sageLine)
                : null,
          ),
          // Preflight failures are explained by SocialAuthService. Disabling
          // this button for a failed Firebase startup looks like a dead tap.
          onPressed: _busy
              ? null
              : () => _work(() async => _finishSignIn(await signIn())),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final user = SocialAuthService.currentUser;
    final legacyEmail =
        user?.providerData.any((p) => p.providerId == 'password') == true;
    final googleLinked =
        user?.providerData.any((p) => p.providerId == 'google.com') == true;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(user == null ? tr("간편 로그인") : tr("내 계정"))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                user == null ? tr("편한 방법으로 시작해요") : tr("함께 가꾸는 나의 계정"),
                style: titleFont(
                  fontSize: 25,
                  color: AppColors.titlePastelGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user == null
                    ? tr("별도의 가입 양식 없이 로그인할 수 있어요. 처음 로그인하면 마음냥 계정이 만들어져요.")
                    : tr("로그인 정보와 서버에서 확인한 구독을 관리해요."),
              ),
              const SizedBox(height: 20),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!,
                      style: const TextStyle(color: AppColors.ink),
                    ),
                  ),
                ),
              if (user == null) ...[
                _providerButton(
                  tr("구글로 계속하기"),
                  Colors.white,
                  AppColors.ink,
                  SocialAuthService.signInWithGoogle,
                ),
                _providerButton(
                  tr("카카오로 계속하기"),
                  const Color(0xFFFEE500),
                  const Color(0xFF191919),
                  () => SocialAuthService.signInWithProvider('kakao'),
                ),
                _providerButton(
                  tr("네이버로 계속하기"),
                  const Color(0xFF03C75A),
                  Colors.white,
                  () => SocialAuthService.signInWithProvider('naver'),
                ),
                _providerButton(
                  tr("페이스북으로 계속하기"),
                  const Color(0xFF0866FF),
                  Colors.white,
                  () => SocialAuthService.signInWithProvider('facebook'),
                ),
                if (!SocialAuthService.firebaseReady)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      tr("이 버전은 계정 연결 준비 중이에요. 기록과 정원은 로그인 없이 이용할 수 있어요."),
                    ),
                  )
                else if (!SocialAuthService.supportsQuickLogin)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      tr(
                        "간편 로그인은 현재 안드로이드 앱에서 이용할 수 있어요. 웹 미리보기에서는 로그인 화면을 확인할 수 있어요.",
                      ),
                    ),
                  )
                else if (!SocialAuthService.browserConfigured)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(tr("카카오·네이버·페이스북 로그인은 현재 연결 준비 중이에요.")),
                  ),
                Text(
                  tr(
                    "기존 구매 내역이 있다면 구매할 때 사용한 로그인 방법을 선택해 주세요. 계정은 자동으로 합쳐지지 않아요.",
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: Text(tr("기존 이메일 계정으로 로그인")),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    AutofillGroup(
                      child: Column(
                        children: [
                          TextField(
                            controller: _email,
                            enabled: !_busy && SocialAuthService.firebaseReady,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(labelText: tr("이메일")),
                          ),
                          TextField(
                            controller: _password,
                            enabled: !_busy && SocialAuthService.firebaseReady,
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) {
                              if (!_busy && SocialAuthService.firebaseReady)
                                _work(_legacyLogin);
                            },
                            decoration: InputDecoration(labelText: tr("비밀번호")),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy || !SocialAuthService.firebaseReady
                          ? null
                          : () => _work(_legacyLogin),
                      child: Text(tr("기존 계정 로그인")),
                    ),
                    TextButton(
                      onPressed: _busy || !SocialAuthService.firebaseReady
                          ? null
                          : () => _work(_resetPassword),
                      child: Text(tr("비밀번호 재설정")),
                    ),
                  ],
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr("{0} 로그인", [_provider]),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (user.displayName?.isNotEmpty == true)
                          Text(user.displayName!),
                        if (user.email?.isNotEmpty == true) Text(user.email!),
                        if (legacyEmail && googleLinked)
                          Text(tr("Google 로그인 연결됨")),
                        const SizedBox(height: 8),
                        Text(_ready ? tr("계정 확인 완료") : tr("계정 확인이 필요해요")),
                      ],
                    ),
                  ),
                ),
                if (user.isAnonymous)
                  Text(
                    tr(
                      "임시 계정으로 이용 중이에요. 로그아웃 후 간편 로그인을 선택해 주세요. 이 기기의 기록은 그대로 유지돼요.",
                    ),
                  ),
                if (legacyEmail && !user.emailVerified && !_ready) ...[
                  Text(tr("기존 이메일 계정은 인증 후 구독·구매·공개 정원을 이용할 수 있어요.")),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => _work(_verifyEmail),
                        child: Text(tr("이메일 인증 확인")),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _work(_resendVerification),
                        child: Text(tr("인증 메일 다시 받기")),
                      ),
                    ],
                  ),
                ] else if (!user.isAnonymous)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _work(() => _finishSignIn(true)),
                    child: Text(
                      widget.returnWhenReady
                          ? tr("이 계정으로 계속하기")
                          : tr("계정 상태 다시 확인"),
                    ),
                  ),
                if (legacyEmail &&
                    !googleLinked &&
                    SocialAuthService.supportsQuickLogin)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _work(_linkGoogle),
                    child: Text(tr("현재 계정에 Google 로그인 연결")),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _work(_signOut),
                  child: Text(tr("로그아웃")),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(tr("기록 백업·계정 삭제 관리")),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DataSafetyScreen(),
                            ),
                          );
                          await _readAccount();
                        },
                ),
              ],
              const Divider(height: 32),
              Text(
                tr(
                  "로그인해도 기록과 정원이 자동으로 다른 기기로 옮겨지지는 않아요. 기기를 바꿀 때는 기록 백업·복원을 이용해 주세요.",
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsOfServiceScreen(),
                            ),
                          ),
                    child: Text(tr("이용약관")),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          ),
                    child: Text(tr("개인정보처리방침")),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
