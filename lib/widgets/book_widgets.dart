import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// '진행 책' 컴포넌트: 옆으로 누운 책이 읽은 만큼 채워짐 (높이 120)
class ProgressBook extends StatelessWidget {
  const ProgressBook({super.key, required this.book, this.onTap});
  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 122,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final double edge = (w * book.progress).clamp(14.0, w).toDouble();
          const pillW = 115.0;
          final double pillLeft = (edge - pillW / 2).clamp(0.0, w - pillW).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: pillLeft,
                top: 0,
                width: pillW,
                height: 28,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('독서 진도', style: AppText.caption),
                      const SizedBox(width: 6),
                      Text('${book.percent}%', style: AppText.label),
                    ],
                  ),
                ),
              ),
              // 남은 부분
              Positioned(
                left: 0,
                right: 0,
                top: 34,
                height: 70,
                child: const DashedBox(
                  color: AppColors.card,
                  borderColor: AppColors.border,
                  radius: 8,
                ),
              ),
              // 책 페이지 단면
              Positioned(
                left: 4,
                right: 4,
                top: 93,
                height: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 읽은 부분
              Positioned(
                left: 0,
                top: 34,
                width: edge,
                height: 70,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    color: book.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // 책등
              Positioned(
                left: 0,
                top: 34,
                width: 14,
                height: 70,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.lerp(book.color, AppColors.text, 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                top: 59,
                right: 16,
                child: Text(book.title, style: AppText.label, overflow: TextOverflow.ellipsis),
              ),
              if (!book.isFinished)
                Positioned(
                  left: edge - 0.75,
                  top: 34,
                  width: 1.5,
                  height: 70,
                  child: const CustomPaint(painter: _DashedVLinePainter()),
                ),
              Positioned(left: 0, bottom: 0, child: Text('시작', style: AppText.caption)),
              Positioned(right: 0, bottom: 0, child: Text('완료', style: AppText.caption)),
            ],
          );
        }),
      ),
    );
  }
}

/// '쌓인 책' 컴포넌트 (높이 46)
///
/// [progress]만큼 왼쪽부터 표지 색이 **불투명**하게 채워지고,
/// 아직 안 읽은 부분은 **반투명** + 점선 테두리로 보여요.
class StackedBook extends StatelessWidget {
  const StackedBook({
    super.key,
    required this.title,
    required this.trailing,
    required this.color,
    this.progress = 1,
    this.width,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String trailing;
  final Color color;
  final double progress; // 0~1
  final double? width;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: width,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF734D26).withValues(alpha: 0.18),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 안 읽은 부분: 반투명
            DashedBox(
              color: Color.alphaBlend(color.withValues(alpha: 0.35), AppColors.card),
              borderColor: p < 1 ? color : Colors.transparent,
              radius: 6,
            ),
            // 읽은 부분: 불투명
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: p),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
            if (p > 0 && p < 1)
              LayoutBuilder(
                builder: (context, c) => Padding(
                  padding: EdgeInsets.only(left: c.maxWidth * p - 0.75),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 1.5,
                      height: 46,
                      child: CustomPaint(painter: _DashedVLinePainter()),
                    ),
                  ),
                ),
              ),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppText.label, overflow: TextOverflow.ellipsis),
                  ),
                  Text(trailing, style: AppText.caption.copyWith(color: AppColors.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 점선 테두리가 있는 둥근 사각형 (Figma의 '남은 부분', '빈 자리')
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.color,
    required this.borderColor,
    this.radius = 8,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final Color borderColor;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color, borderColor, radius, strokeWidth),
      child: const SizedBox.expand(),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter(this.color, this.borderColor, this.radius, this.strokeWidth);
  final Color color;
  final Color borderColor;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), stroke);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.borderColor != borderColor;
}

/// 세로 점선 (현재 읽은 위치)
class _DashedVLinePainter extends CustomPainter {
  const _DashedVLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = size.width;
    final x = size.width / 2;
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + 4).clamp(0, size.height).toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CharacterShelf extends StatelessWidget {
  const CharacterShelf({
    super.key,
    required this.books,
    this.decoration,
    this.highlightLast = false,
    this.bubble,
    this.onBookTap,
  });

  final List<Book> books;
  final ShelfDeco? decoration;
  final bool highlightLast; // 09 완독: 방금 꽂은 책 테두리
  final String? bubble;

  /// 책등을 눌렀을 때 (없으면 제목·쪽수 말풍선만 보여 줌)
  final ValueChanged<Book>? onBookTap;

  // 책장 크기 (캔버스 345x340 기준): 새싹이 몸 안에 들어가는 최대 크기
  // 얼굴(볼·입) 바로 아래에서 시작해 몸 아래쪽 곡선 안쪽까지
  static const _canvasH = 340.0;
  static const _shelfRect = Rect.fromLTWH(40, 142, 265, 186);
  static const _shelfPad = 10.0;
  static const _rowGap = 8.0;
  static const _rowH = 79.0; // 책 칸 높이: (186 - 10*2 - 8) / 2
  static const _rowInner = 233.0; // 책 칸 안쪽 너비: 265 - 10*2 - 6*2
  static const _decoSize = 52.0;
  static const _gap = 3.0;

  /// 책 두께: 쪽수에 비례 (100쪽 ≈ 16.5, 300쪽 ≈ 27.5, 500쪽 ≈ 38.5, 최대 40)
  static double thicknessOf(Book b) => (11 + b.totalPages * 0.055).clamp(15.0, 40.0).toDouble();

  /// 책 높이: 60~76 사이에서 책마다 조금씩 다르게
  static double heightOf(Book b) => 60.0 + (b.title.hashCode.abs() % 5) * 4;

  @override
  Widget build(BuildContext context) {
    // 1번 칸: 두께대로 채우기
    final row1 = <Book>[];
    var used = 0.0;
    var i = 0;
    for (; i < books.length; i++) {
      final w = thicknessOf(books[i]) + _gap;
      if (used + w > _rowInner) break;
      row1.add(books[i]);
      used += w;
    }
    // 2번 칸: 장식 자리를 남기고 채우기, 넘치면 '+N권' 표시
    final decoW = decoration != null ? _decoSize + _gap : 0.0;
    final rest = books.sublist(i);
    var cap = _rowInner - decoW;
    final restW = rest.fold<double>(0, (a, b) => a + thicknessOf(b) + _gap);
    if (restW > cap) cap -= 37; // '+N권' 배지 자리
    final row2 = <Book>[];
    var used2 = 0.0;
    for (final b in rest) {
      final w = thicknessOf(b) + _gap;
      if (used2 + w > cap) break;
      row2.add(b);
      used2 += w;
    }
    final hidden = rest.length - row2.length;
    final emptySlots =
        hidden > 0 ? 0 : ((cap - used2) / (20 + _gap)).floor().clamp(0, 3).toInt();

    Widget spine(Book b) {
      final w = thicknessOf(b);
      final h = heightOf(b);
      final fontSize = w < 19 ? 9.5 : (w < 26 ? 10.5 : 11.5);
      final lineH = fontSize * 1.12;
      final fit = ((h - 8) / lineH).floor();
      final chars = b.title.replaceAll(' ', '').characters.toList();
      final shown = chars.length <= fit ? chars : [...chars.take(fit - 1), '⋮'];
      final highlight = highlightLast && identical(b, books.last); // 방금 꽂은 책
      return Tooltip(
        message: '${b.title} · ${b.totalPages}쪽',
        triggerMode: onBookTap == null ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
        child: GestureDetector(
          onTap: onBookTap == null ? null : () => onBookTap!(b),
          child: Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(right: _gap),
          padding: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: b.color,
            borderRadius: BorderRadius.circular(3),
            border: highlight ? Border.all(color: AppColors.primary, width: 1.7) : null,
          ),
          child: Column(
            children: [
              for (final ch in shown)
                Text(
                  ch,
                  style: AppText.caption.copyWith(
                    fontSize: fontSize,
                    height: 1.12,
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        ),
      );
    }

    Widget emptySpine() => Container(
          width: 20,
          height: 64,
          margin: const EdgeInsets.only(right: 3),
          child: const DashedBox(color: AppColors.card, borderColor: AppColors.tan, radius: 3),
        );

    Widget shelfRow(List<Widget> children) => Container(
          height: _rowH,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: children),
        );

    final shelf = SizedBox(
      width: 345,
      height: _canvasH,
      child: Stack(
        children: [
          SvgPicture.asset('assets/svg/sprout_big.svg', width: 345, height: 340),
          Positioned.fromRect(
            rect: _shelfRect,
            child: Container(
              padding: const EdgeInsets.all(_shelfPad),
              decoration: BoxDecoration(
                color: AppColors.shelf,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  shelfRow([for (final b in row1) spine(b)]),
                  const SizedBox(height: _rowGap),
                  shelfRow([
                    for (final b in row2) spine(b),
                    if (hidden > 0)
                      Container(
                        width: 34,
                        height: 22,
                        margin: const EdgeInsets.only(right: _gap, bottom: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$hidden권',
                          style: AppText.caption.copyWith(fontSize: 10, color: AppColors.primary),
                        ),
                      ),
                    for (var k = 0; k < emptySlots; k++) emptySpine(),
                    if (decoration != null)
                      SvgPicture.asset(decoration!.asset, width: _decoSize, height: _decoSize),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      final scale = (c.maxWidth / 345).clamp(0.5, 1.2);
      return SizedBox(
        width: c.maxWidth,
        height: _canvasH * scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: FittedBox(child: shelf)),
            if (bubble != null)
              Positioned(
                right: -10 * scale,
                top: 46 * scale,
                child: SpeechBubble(text: bubble!),
              ),
          ],
        ),
      );
    });
  }
}

/// 하단 탭바 (책장 / 읽을 책 / 추천)
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    ('책장', 'assets/svg/ic_tab_shelf.svg'),
    ('읽을 책', 'assets/svg/ic_tab_toread.svg'),
    ('추천', 'assets/svg/ic_tab_reco.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          _items[i].$2,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            i == index ? AppColors.primary : AppColors.subText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _items[i].$1,
                          style: AppText.caption.copyWith(
                            color: i == index ? AppColors.primary : AppColors.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
