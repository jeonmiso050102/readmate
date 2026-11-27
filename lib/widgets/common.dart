import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// 모든 화면 공통: 따뜻한 크림색 벽 + 위쪽 햇살 그라데이션 + 비스듬한 햇빛 줄기
///
/// [background]를 주면 그 위에(내용 뒤에) 그림 배경을 깔 수 있어요. (예: 홈의 서재 풍경)
class SunScaffold extends StatelessWidget {
  const SunScaffold({
    super.key,
    required this.body,
    this.bottom,
    this.bottomNavigationBar,
    this.background,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 0),
  });

  final Widget body;
  final Widget? bottom; // 화면 하단 고정 버튼 영역
  final Widget? bottomNavigationBar;
  final Widget? background;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // 위쪽에서 들어오는 따뜻한 햇살
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sun.withValues(alpha: 0.55),
                    AppColors.sun.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (background != null) Positioned.fill(child: background!),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: SunRayPainter())),
          ),
          SafeArea(
            bottom: bottomNavigationBar == null,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: padding,
                    child: body,
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: bottom,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 오른쪽 위 창문에서 비스듬히 들어오는 부드러운 햇빛 줄기
class SunRayPainter extends CustomPainter {
  const SunRayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    for (final (x, width) in [(1.02, 0.14), (0.80, 0.07), (0.64, 0.11)]) {
      final path = Path()
        ..moveTo(w * x, 0)
        ..lineTo(w * (x + width), 0)
        ..lineTo(w * (x + width) - h * 0.5, h * 0.7)
        ..lineTo(w * x - h * 0.5, h * 0.7)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 갈색 채움 버튼 (높이 54, 둥근 모서리 + 부드러운 그림자, 아이콘 선택)
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.iconAsset,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? iconAsset; // 예: 'assets/svg/ic_book_open.svg'

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          foregroundColor: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.card),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconAsset != null) ...[
                    SvgPicture.asset(iconAsset!, width: 22, height: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(label, style: AppText.bodyBold.copyWith(color: AppColors.card)),
                ],
              ),
      ),
    );
  }
}

/// 테두리 버튼 (책 추가하기, 포기하기)
class OutlineButtonX extends StatelessWidget {
  const OutlineButtonX({super.key, required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label, style: AppText.bodyBold.copyWith(color: AppColors.primary)),
      ),
    );
  }
}

/// 배경 없는 텍스트 버튼 (나중에 놓기, 다음 책 고르기)
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: AppText.bodyBold.copyWith(color: AppColors.subText)),
      ),
    );
  }
}

/// 라벨 + 입력칸 (입력 필드 컴포넌트)
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.suffixText,
    this.autofillHints,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final String? suffixText;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    final isMultiline = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          minLines: minLines,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          style: isMultiline ? AppText.body : AppText.bodyBold,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body.copyWith(color: AppColors.subText.withValues(alpha: 0.6)),
            suffixText: suffixText,
            suffixStyle: AppText.bodyBold.copyWith(color: AppColors.subText),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary),
            errorBorder: border(Colors.redAccent),
            focusedErrorBorder: border(Colors.redAccent),
            errorStyle: AppText.caption.copyWith(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

/// 상단 바: 뒤로 아이콘 + 제목
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          InkResponse(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            radius: 22,
            child: SvgPicture.asset('assets/svg/ic_back.svg', width: 24, height: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: AppText.bodyBold, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

enum SproutMood { basic, happy, sleep }

/// 새싹이 캐릭터 (표정=기본/기쁨/잠듦), 원본 비율 120x112
class Sprout extends StatelessWidget {
  const Sprout({super.key, this.mood = SproutMood.basic, this.width = 84});
  final SproutMood mood;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/sprout_${mood.name}.svg',
      width: width,
      height: width * 112 / 120,
    );
  }
}

/// 말풍선 (Gaegu Bold 19, 꼬리 포함)
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C6633).withValues(alpha: 0.16),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(text, style: AppText.bubble),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: CustomPaint(size: const Size(18, 11), painter: _TailPainter()),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.card);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 새싹이 + 말풍선 가로 배치
class SproutWithBubble extends StatelessWidget {
  const SproutWithBubble({
    super.key,
    required this.text,
    this.mood = SproutMood.basic,
    this.sproutWidth = 86,
  });
  final String text;
  final SproutMood mood;
  final double sproutWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Sprout(mood: mood, width: sproutWidth),
        const SizedBox(width: 6),
        Flexible(child: SpeechBubble(text: text)),
      ],
    );
  }
}

/// 둥근 카드 (#FFFBEF, radius 16)
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
        boxShadow: AppColors.softShadow(),
      ),
      child: child,
    );
  }
}

/// 세그먼트 선택 (책장/캐릭터, 초보자/중급자/고급자)
class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });
  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    items[i],
                    style: i == selected ? AppText.label : AppText.subLabel,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
