import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/auth_field.dart';

/// 회원가입 화면
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nicknameCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pwConfirm = _pwConfirmCtrl.text;

    if (email.isEmpty || pw.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력해주세요');
      return;
    }
    if (!AuthService.isValidEmail(email)) {
      _showSnack('올바른 이메일 형식이 아니에요');
      return;
    }
    if (pw.length < 6) {
      _showSnack('비밀번호는 6자 이상으로 만들어주세요');
      return;
    }
    if (pw != pwConfirm) {
      _showSnack('비밀번호가 일치하지 않아요');
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: email,
      password: pw,
      nickname: nickname,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      // 회원가입 성공 -> AuthProvider.currentUser가 채워지고
      // main.dart의 _AppRoot가 자동으로 홈 화면으로 전환합니다.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showSnack(auth.errorMessage ?? '회원가입에 실패했어요');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.goldSoft),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '회원가입',
                      style: titleFont(fontSize: 24, color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '나만의 그림자 정원을 시작해보세요',
                      style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 28),
                    AuthField(
                      controller: _emailCtrl,
                      label: '이메일',
                      hint: 'example@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AuthField(
                      controller: _nicknameCtrl,
                      label: '닉네임',
                      hint: '그림자 정원에서 불릴 이름',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    AuthField(
                      controller: _pwCtrl,
                      label: '비밀번호',
                      hint: '6자 이상 입력해주세요',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscure1,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure1
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.inkSoft,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AuthField(
                      controller: _pwConfirmCtrl,
                      label: '비밀번호 확인',
                      hint: '비밀번호를 다시 입력해주세요',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscure2,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(
                          _obscure2
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.inkSoft,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blobMintAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                '회원가입',
                                style: pathLabelFont(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '이미 계정이 있으신가요?',
                          style: bodyFont(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '로그인',
                            style: bodyFont(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blobMintAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
