import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/auth_field.dart';
import 'signup_screen.dart';

/// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (email.isEmpty || pw.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력해주세요');
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.logIn(email: email, password: pw);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      _showSnack(auth.errorMessage ?? '로그인에 실패했어요');
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
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFFFF6DF),
                              AppColors.goldSoft,
                              AppColors.gold,
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        ),
                        child: const Text(
                          '🐈‍⬛',
                          style: TextStyle(fontSize: 38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '고양이 그림자 정원',
                      textAlign: TextAlign.center,
                      style: titleFont(
                        fontSize: 24,
                        color: AppColors.titlePastelGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '다시 만나서 반가워요',
                      textAlign: TextAlign.center,
                      style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 32),
                    AuthField(
                      controller: _emailCtrl,
                      label: '이메일',
                      hint: 'example@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AuthField(
                      controller: _pwCtrl,
                      label: '비밀번호',
                      hint: '비밀번호를 입력해주세요',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscure,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.inkSoft,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                                '로그인',
                                style: bodyFont(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '아직 계정이 없으신가요?',
                          style: bodyFont(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            '회원가입',
                            style: bodyFont(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldSoft,
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
