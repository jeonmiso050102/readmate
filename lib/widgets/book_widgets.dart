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
          final edge = (w * book.progress).clamp(14.0, w);
          const pillW = 115.0;
          final pillLeft = (edge - pillW / 2).clamp(0.0, w - pillW);
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
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    color: AppColors.checkbox,
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
                  child: const ColoredBox(color: AppColors.primary),
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

/// '쌓인 책' 컴포넌트 (높이 46, 표지 색 배경)
class StackedBook extends StatelessWidget {
  const StackedBook({
    super.key,
    required this.title,
    required this.trailing,
    required this.color,
    this.width,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String trailing;
  final Color color;
  final double? width;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: 46,
        padding: const EdgeInsets.only(left: 20, right: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF734D26).withOpacity(0.18),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppText.label, overflow: TextOverflow.ellipsis),
            ),
            Text(trailing, style: AppText.caption.copyWith(color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}

/// '캐릭터 책장' 컴포넌트: 큰 새싹이 몸체 안에 책장이 들어 있음 (원본 345x340)
class CharacterShelf extends StatelessWidget {
  const CharacterShelf({
    super.key,
    required this.books,
    this.decoration,
    this.highlightLast = false,
    this.bubble,
  });

  final List<Book> books;
  final ShelfDeco? decoration;
  final bool highlightLast; // 09 완독: 방금 꽂은 책 테두리
  final String? bubble;

  static const _heights = [56.0, 48.0, 58.0, 50.0, 54.0, 46.0, 52.0];
  static const _widths = [24.0, 20.0, 26.0, 22.0, 24.0, 20.0, 22.0];
  static const _perRow = 7;

  @override
  Widget build(BuildContext context) {
    final row1 = books.take(_perRow).toList();
    final row2 = books.skip(_perRow).take(_perRow - 3).toList();
    final emptySlots = (3 - row2.length).clamp(0, 3);

    Widget spine(Book b, int i, bool isLast) => Container(
          width: _widths[i % _widths.length],
          height: _heights[i % _heights.length],
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: b.color,
            borderRadius: BorderRadius.circular(3),
            border: isLast && highlightLast
                ? Border.all(color: AppColors.primary, width: 1.7)
                : null,
          ),
        );

    Widget emptySpine() => Container(
          width: 24,
          height: 52,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.tan, width: 1.5),
          ),
        );

    Widget shelfRow(List<Widget> children) => Container(
          height: 66,
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
      height: 340,
      child: Stack(
        children: [
          SvgPicture.asset('assets/svg/sprout_big.svg', width: 345, height: 340),
          Positioned(
            left: 48,
            top: 150,
            width: 249,
            height: 166,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.shelf,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  shelfRow([
                    for (var i = 0; i < row1.length; i++)
                      spine(row1[i], i, row2.isEmpty && i == row1.length - 1),
                  ]),
                  const SizedBox(height: 10),
                  shelfRow([
                    for (var i = 0; i < row2.length; i++)
                      spine(row2[i], i + 3, i == row2.length - 1),
                    for (var i = 0; i < emptySlots; i++) emptySpine(),
                    if (decoration != null)
                      SvgPicture.asset(decoration!.asset, width: 48, height: 48),
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
        height: 340 * scale,
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
