import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 00 회원가입
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nickname, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용약관 및 개인정보 처리에 동의해 주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signUp(
            nickname: _nickname.text,
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
      // 가입과 동시에 로그인되므로 AuthGate(첫 화면)로 돌아가 홈이 보이게 함
      Navigator.of(context).popUntil((r) => r.isFirst);
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
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(label: '가입하기', loading: _loading, onPressed: _submit),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('이미 계정이 있나요?', style: AppText.bodySub),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Text('로그인', style: AppText.label.copyWith(color: AppColors.link)),
              ),
            ],
          ),
        ],
      ),
      body: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: '회원가입'),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Sprout(width: 84),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('반가워요!', style: AppText.heading),
                        const SizedBox(height: 2),
                        Text('새싹이와 함께 완독 습관을 만들어요', style: AppText.subLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: '닉네임',
                controller: _nickname,
                hint: '새싹독서가',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.nickname],
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '닉네임을 입력해 주세요.';
                  if (s.length > 12) return '닉네임은 12자 이내로 정해 주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
                hint: '6자 이상',
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) =>
                    (v == null || v.length < 6) ? '비밀번호는 6자 이상으로 정해 주세요.' : null,
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: '비밀번호 확인',
                controller: _confirm,
                hint: '비밀번호를 한 번 더 입력',
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (v) => v != _password.text ? '비밀번호가 서로 달라요.' : null,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _agreed ? AppColors.checkbox : AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: _agreed ? null : Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: _agreed
                          ? SvgPicture.asset('assets/svg/ic_check.svg', width: 16, height: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('서비스 이용약관 및 개인정보 처리에 동의해요', style: AppText.body),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
