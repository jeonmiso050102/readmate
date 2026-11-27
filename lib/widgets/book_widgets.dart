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

/// '캐릭터 책장': 진짜 나무 책장 + 그 위에 기대 앉은 새싹이 (01 홈, 09 완독, 10 꾸미기)
///
/// - 다 읽은 책이 쪽수에 비례한 두께로 세로로 꽂히고 제목이 세로로 적혀요.
/// - [onBookTap]이 있으면 책등을 눌러 그 책의 기록을 열고, 길게 누르면 제목 말풍선이 떠요.
class CharacterShelf extends StatefulWidget {
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
  final bool highlightLast; // 09 완독: 방금 꽂은 책 강조
  final String? bubble;

  /// 책등을 눌렀을 때 (없으면 제목·쪽수 말풍선만 보여 줌)
  final ValueChanged<Book>? onBookTap;

  // 설계 크기 (캔버스 320 x 336 기준, 화면 너비에 맞춰 늘고 줄어요)
  static const _w = 320.0;
  static const _topSpace = 100.0; // 책장 위 새싹이 자리
  static const _framePad = 12.0;
  static const _rowH = 100.0; // 책 칸 높이
  static const _rowGap = 12.0; // 칸 사이 선반 두께
  static const _rowInner = 280.0; // 칸 안쪽 너비: 320 - 12*2 - 8*2
  static const _gap = 3.0;
  static const _decoSize = 58.0;
  static const _border = 2.0;
  static const _frameH = _framePad * 2 + _rowH * 2 + _rowGap + _border * 2;
  static const _h = _topSpace + _frameH;

  /// 책 두께: 쪽수에 비례 (100쪽 ≈ 19, 300쪽 ≈ 31, 500쪽 ≈ 43, 최대 46)
  static double thicknessOf(Book b) => (13 + b.totalPages * 0.06).clamp(18.0, 46.0).toDouble();

  /// 책 높이: 78~94 사이에서 책마다 조금씩 다르게
  static double heightOf(Book b) => 78.0 + (b.title.hashCode.abs() % 5) * 4;

  @override
  State<CharacterShelf> createState() => _CharacterShelfState();
}

/// 한 쪽(페이지)에 꽂히는 책: 위 칸, 아래 칸
class _ShelfPage {
  _ShelfPage(this.row1, this.row2);
  final List<Book> row1;
  final List<Book> row2;
}

class _CharacterShelfState extends State<CharacterShelf> {
  static const _w = CharacterShelf._w;
  static const _topSpace = CharacterShelf._topSpace;
  static const _framePad = CharacterShelf._framePad;
  static const _rowH = CharacterShelf._rowH;
  static const _rowGap = CharacterShelf._rowGap;
  static const _rowInner = CharacterShelf._rowInner;
  static const _gap = CharacterShelf._gap;
  static const _decoSize = CharacterShelf._decoSize;
  static const _border = CharacterShelf._border;
  static const _frameH = CharacterShelf._frameH;
  static const _h = CharacterShelf._h;

  late int _page;

  @override
  void initState() {
    super.initState();
    // 완독 화면에서는 방금 꽂은 책이 있는 마지막 쪽부터
    _page = widget.highlightLast ? _pack(widget.books).length - 1 : 0;
  }

  @override
  void didUpdateWidget(covariant CharacterShelf old) {
    super.didUpdateWidget(old);
    final count = _pack(widget.books).length;
    if (_page >= count) _page = count - 1;
  }

  void _go(int p, int count) {
    if (p < 0 || p >= count) return;
    setState(() => _page = p);
  }

  /// 책을 쪽(페이지)별로 나누기: 위 칸을 채우고, 아래 칸은 장식 자리를 남기고 채움
  List<_ShelfPage> _pack(List<Book> books) {
    final pages = <_ShelfPage>[];
    final decoW = widget.decoration != null ? _decoSize + _gap : 0.0;
    var i = 0;
    do {
      final r1 = <Book>[];
      var used = 0.0;
      while (i < books.length) {
        final w = CharacterShelf.thicknessOf(books[i]) + _gap;
        if (used + w > _rowInner && r1.isNotEmpty) break;
        r1.add(books[i]);
        used += w;
        i++;
      }
      final r2 = <Book>[];
      used = 0;
      while (i < books.length) {
        final w = CharacterShelf.thicknessOf(books[i]) + _gap;
        if (used + w > _rowInner - decoW && r2.isNotEmpty) break;
        r2.add(books[i]);
        used += w;
        i++;
      }
      pages.add(_ShelfPage(r1, r2));
    } while (i < books.length);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pack(widget.books);
    final page = _page.clamp(0, pages.length - 1).toInt();
    final row1 = pages[page].row1;
    final row2 = pages[page].row2;
    final isLastPage = page == pages.length - 1;
    final paged = pages.length > 1;
    // 쪽이 여러 개면 책장 아래에 ‹ 1 / 2 › 를 걸어 둘 자리
    final canvasH = _h + (paged ? 22 : 0);
    // 빈 자리 점선은 마지막 쪽에만
    final used2 = row2.fold<double>(0, (a, b) => a + CharacterShelf.thicknessOf(b) + _gap);
    final cap2 = _rowInner - (widget.decoration != null ? _decoSize + _gap : 0);
    final emptySlots =
        isLastPage ? ((cap2 - used2) / (24 + _gap)).floor().clamp(0, 3).toInt() : 0;

    Widget spine(Book b) {
      final w = CharacterShelf.thicknessOf(b);
      final h = CharacterShelf.heightOf(b);
      final fontSize = w < 22 ? 10.0 : (w < 30 ? 11.0 : 12.0);
      final lineH = fontSize * 1.12;
      final fit = ((h - 10) / lineH).floor();
      final chars = b.title.replaceAll(' ', '').characters.toList();
      final shown = chars.length <= fit ? chars : [...chars.take(fit - 1), '⋮'];
      final highlight = widget.highlightLast && identical(b, widget.books.last); // 방금 꽂은 책
      final c = b.color;
      return Tooltip(
        message: '${b.title} · ${b.totalPages}쪽',
        triggerMode: widget.onBookTap == null ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
        child: GestureDetector(
          onTap: widget.onBookTap == null ? null : () => widget.onBookTap!(b),
          child: Container(
            width: w,
            height: h,
            margin: const EdgeInsets.only(right: _gap),
            decoration: BoxDecoration(
              color: c, // 책등은 표지 색만
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
                bottom: Radius.circular(3),
              ),
              border: highlight ? Border.all(color: AppColors.primary, width: 2) : null,
              boxShadow: [
                if (highlight)
                  BoxShadow(color: const Color(0xFFFFE6A0).withValues(alpha: 0.9), blurRadius: 10),
                BoxShadow(
                  color: const Color(0xFF6B4A2B).withValues(alpha: 0.18),
                  offset: const Offset(1.5, 0),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 5),
                Expanded(
                  child: Column(
                    children: [
                      for (final ch in shown)
                        Text(
                          ch,
                          style: AppText.caption.copyWith(
                            fontSize: fontSize,
                            height: 1.12,
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
              ],
            ),
          ),
        ),
      );
    }

    Widget emptySpine() => Container(
          width: 24,
          height: 82,
          margin: const EdgeInsets.only(right: _gap),
          child: DashedBox(
            color: Colors.white.withValues(alpha: 0.45),
            borderColor: AppColors.tan,
            radius: 5,
          ),
        );

    Widget compartment(List<Widget> children, {required bool top}) => Container(
          height: _rowH,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // 칸 안쪽: 위쪽이 살짝 어두운 깊이감
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(AppColors.shelfInner, AppColors.wood, 0.28)!, AppColors.shelfInner],
              stops: const [0, 0.22],
            ),
          ),
          child: Stack(
            children: [
              // 칸 구석의 작은 새싹 장식
              Positioned(
                right: 2,
                top: top ? 6 : null,
                bottom: top ? null : 6,
                child: SvgPicture.asset('assets/svg/leaf_sprig.svg', width: 22),
              ),
              Positioned.fill(
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: children),
              ),
            ],
          ),
        );

    final canvas = SizedBox(
      width: _w,
      height: canvasH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 책장 그림자 (바닥)
          Positioned(
            left: 18,
            right: 18,
            top: _h - 8,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4A2B).withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // 나무 프레임
          Positioned(
            left: 0,
            right: 0,
            top: _topSpace,
            height: _frameH,
            child: Container(
              padding: const EdgeInsets.all(_framePad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.woodLight, AppColors.wood],
                ),
                border: Border.all(color: AppColors.woodDark.withValues(alpha: 0.55), width: _border),
                boxShadow: AppColors.softShadow(1.4),
              ),
              child: Column(
                children: [
                  compartment([for (final b in row1) spine(b)], top: true),
                  const SizedBox(height: _rowGap),
                  compartment([
                    for (final b in row2) spine(b),
                    for (var k = 0; k < emptySlots; k++) emptySpine(),
                    if (widget.decoration != null)
                      SvgPicture.asset(widget.decoration!.asset, width: _decoSize, height: _decoSize),
                  ], top: false),
                ],
              ),
            ),
          ),
          // 책장 위에 손을 얹고 기대 앉은 새싹이 (아랫부분이 프레임 앞으로 살짝 겹침)
          const Positioned(
            left: (_w - 124) / 2,
            top: _topSpace - 100,
            child: Sprout(mood: SproutMood.basic, width: 124),
          ),
          if (paged)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: _PageControl(
                  page: page,
                  count: pages.length,
                  onPrev: page > 0 ? () => _go(page - 1, pages.length) : null,
                  onNext: page < pages.length - 1 ? () => _go(page + 1, pages.length) : null,
                ),
              ),
            ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      final scale = (c.maxWidth / _w).clamp(0.6, 1.25).toDouble();
      final shelf = SizedBox(
        width: c.maxWidth,
        height: canvasH * scale + 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _w * scale,
                height: canvasH * scale,
                child: FittedBox(child: canvas),
              ),
            ),
            if (widget.bubble != null)
              Positioned(
                right: 0,
                top: 6 * scale,
                child: SpeechBubble(text: widget.bubble!),
              ),
          ],
        ),
      );
      if (!paged) return shelf;
      // 옆으로 밀어서 넘기기
      return GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -150) _go(page + 1, pages.length);
          if (v > 150) _go(page - 1, pages.length);
        },
        child: shelf,
      );
    });
  }
}

/// 책장 쪽 넘기기: ‹  1 / 2  ›
class _PageControl extends StatelessWidget {
  const _PageControl({required this.page, required this.count, this.onPrev, this.onNext});
  final int page;
  final int count;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, VoidCallback? onTap) => Material(
          color: onTap == null ? AppColors.beige.withValues(alpha: 0.5) : AppColors.card,
          shape: const CircleBorder(),
          elevation: onTap == null ? 0 : 1,
          shadowColor: const Color(0x338C6633),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(icon,
                  size: 20, color: onTap == null ? AppColors.subText.withValues(alpha: 0.4) : AppColors.primary),
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        arrow(Icons.chevron_left, onPrev),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppColors.softShadow(0.6),
          ),
          child: Text('${page + 1} / $count', style: AppText.label.copyWith(color: AppColors.primary)),
        ),
        const SizedBox(width: 8),
        arrow(Icons.chevron_right, onNext),
      ],
    );
  }
}

/// 하단 탭바 (책장 / 읽을 책 / 추천): 화면 아래에 떠 있는 둥근 바
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: AppColors.softShadow(1.3),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    radius: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == 0 && index == 0)
                          // 선택된 '책장' 탭은 알록달록한 책 아이콘
                          SvgPicture.asset('assets/svg/ic_tab_shelf_active.svg', width: 26, height: 26)
                        else
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
                            fontWeight: i == index ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // 선택 표시: 세이지 그린 막대
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == index ? 26 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(999),
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
