import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 00 로그인
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signIn(email: _email.text, password: _password.text);
      // 로그인 성공 시 AuthGate가 홈(01 캐릭터 책장)으로 전환합니다.
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SunScaffold(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      bottom: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('아직 회원이 아니신가요?', style: AppText.bodySub),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(Routes.signup),
            child: Text('여기를 눌러 회원가입', style: AppText.label.copyWith(color: AppColors.link)),
          ),
        ],
      ),
      body: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 새싹이 영역 (240x150)
              SizedBox(
                width: 240,
                height: 150,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: 45,
                      top: 10,
                      child: Sprout(mood: SproutMood.happy, width: 150),
                    ),
                    Positioned(
                      left: 140,
                      top: -14,
                      child: SpeechBubble(text: '같이 끝까지 읽자!'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('리드메이트', style: AppText.title),
              const SizedBox(height: 12),
              Text('끝까지 읽는 습관, 완독 습관 앱', style: AppText.subLabel),
              const SizedBox(height: 30),
              LabeledField(
                label: '이메일',
                controller: _email,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '이메일을 입력해 주세요.';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                    return '이메일 형식이 올바르지 않아요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: '비밀번호',
                controller: _password,
                hint: '비밀번호',
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: '로그인', loading: _loading, onPressed: _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
