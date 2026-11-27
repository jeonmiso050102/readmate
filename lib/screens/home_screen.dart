import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 01 홈 · 캐릭터 책장 (동화풍 서재)
///
/// 기능은 그대로: 꾸미기 → 10, 책등 누르기 → 책 기록, 지금 읽는 책 수정 → 02,
/// 읽기 시작/이어서 읽기 → 04/08, 책이 없으면 첫 책 추가 → 02
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _year; // null = 전체

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final book = s.current;
    final years = s.shelfYears;
    if (_year != null && !years.contains(_year)) _year = null;
    final shelfBooks = s.shelfOf(_year);
    return SunScaffold(
      background: const _StudyBackground(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- 제목 + 꾸미기 ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('내 책장', style: AppText.title),
                        const SizedBox(width: 6),
                        SvgPicture.asset('assets/svg/leaf_sprig.svg', width: 26),
                      ],
                    ),
                    Text(
                      _year == null
                          ? '완독한 책 ${s.shelf.length}권'
                          : '$_year년에 완독한 책 ${shelfBooks.length}권',
                      style: AppText.label.copyWith(color: AppColors.sageDark),
                    ),
                  ],
                ),
              ),
              _PillButton(
                icon: 'assets/svg/ic_deco.svg',
                label: '꾸미기',
                onTap: () => Navigator.of(context).pushNamed(Routes.decorate),
              ),
            ],
          ),
          // ---- 전체 / 년도별 보기 ----
          if (years.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: '전체', selected: _year == null, onTap: () => setState(() => _year = null)),
                  for (final y in years) ...[
                    const SizedBox(width: 8),
                    _FilterChip(label: '$y년', selected: _year == y, onTap: () => setState(() => _year = y)),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),

          // ---- 책상 위의 나무 책장 + (꾸미기에서 놓은) 소품 ----
          _DeskScene(
            props: s.placedDeskProps,
            child: CharacterShelf(
              key: ValueKey(_year), // 보기 바꾸면 1쪽부터
              books: shelfBooks,
              decoration: s.placedDecoration,
              bubble: '오늘도 조금 더!',
              // 다 읽은 책을 누르면 그 책의 독서 기록·줄거리 보기
              onBookTap: (b) => Navigator.of(context).pushNamed(Routes.bookDetail, arguments: b),
            ),
          ),
          const SizedBox(height: 18),

          // ---- 지금 읽는 책 카드 ----
          _CurrentBookCard(book: book),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 전체 / 년도 선택 칩
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.sage : AppColors.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.sage : AppColors.border),
          boxShadow: selected ? AppColors.softShadow(0.6) : null,
        ),
        child: Text(
          label,
          style: AppText.label.copyWith(
            color: selected ? Colors.white : AppColors.subText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 둥근 알약 모양 버튼 (꾸미기)
class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppColors.softShadow(),
      ),
      child: Material(
        color: AppColors.card,
        shape: StadiumBorder(side: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(icon, width: 18, height: 18),
                const SizedBox(width: 5),
                Text(label, style: AppText.label.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 책장이 올려진 책상 + 양옆 소품(펜 꽂은 머그컵, 꽃병)
class _DeskScene extends StatelessWidget {
  const _DeskScene({required this.child, required this.props});
  final Widget child;
  final Set<DeskProp> props; // 꾸미기에서 놓은 책상 소품

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final shelfW = w * 0.80; // 책장은 가운데, 양옆에 소품 자리
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 책상 상판
          Positioned(
            left: -20,
            right: -20,
            bottom: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.desk.withValues(alpha: 0.95), AppColors.desk.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            right: -20,
            bottom: 28,
            height: 3,
            child: ColoredBox(color: AppColors.woodDark.withValues(alpha: 0.25)),
          ),
          // 소품 (기본은 없음, 꾸미기에서 열어서 놓을 수 있어요)
          if (props.contains(DeskProp.mug))
            Positioned(
              left: -6,
              bottom: 24,
              child: SvgPicture.asset(DeskProp.mug.asset, width: w * 0.15),
            ),
          if (props.contains(DeskProp.vase))
            Positioned(
              right: -10,
              bottom: 22,
              child: SvgPicture.asset(DeskProp.vase.asset, width: w * 0.19),
            ),
          // 책장
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Center(child: SizedBox(width: shelfW, child: child)),
          ),
        ],
      );
    });
  }
}

/// 서재 배경: 왼쪽 책장·담쟁이, 오른쪽 성이 보이는 창문 (내용 뒤에 고정)
class _StudyBackground extends StatelessWidget {
  const _StudyBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 오른쪽 창문
            Positioned(
              right: -w * 0.12,
              top: 64,
              width: w * 0.42,
              child: Opacity(
                opacity: 0.9,
                child: SvgPicture.asset('assets/svg/bg_window.svg', width: w * 0.42),
              ),
            ),
            // 왼쪽 벽 책장
            Positioned(
              left: -w * 0.16,
              top: 130,
              width: w * 0.30,
              child: Opacity(
                opacity: 0.75,
                child: SvgPicture.asset('assets/svg/bg_side_shelf.svg', width: w * 0.30),
              ),
            ),
            // 벽 책장 옆으로 늘어진 담쟁이 (제목을 가리지 않게 제목 아래쪽에)
            Positioned(
              left: -w * 0.05,
              top: 96,
              width: w * 0.22,
              child: Opacity(
                opacity: 0.85,
                child: SvgPicture.asset('assets/svg/scene_ivy.svg', width: w * 0.22),
              ),
            ),
            // 아래쪽은 크림색으로 부드럽게 덮어 카드가 잘 읽히게
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: c.maxHeight * 0.45,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0),
                      AppColors.background.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// 지금 읽는 책 카드 (책갈피 리본, 진행률, 읽기 시작 버튼)
class _CurrentBookCard extends StatelessWidget {
  const _CurrentBookCard({required this.book});
  final Book? book;

  @override
  Widget build(BuildContext context) {
    final b = book;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: AppColors.softShadow(1.3),
          ),
          child: b == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/svg/ic_leaf.svg', width: 18),
                        const SizedBox(width: 6),
                        Text('지금 읽는 책', style: AppText.caption),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('지금 읽는 책이 없어요', style: AppText.bodyBold.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text('읽고 싶은 책을 쌓아 두고 새싹이와 함께 읽어 봐요', style: AppText.bodySub),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: '첫 책 추가하기',
                      iconAsset: 'assets/svg/ic_book_open.svg',
                      onPressed: () => Navigator.of(context).pushNamed(Routes.addBook),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/svg/ic_leaf.svg', width: 18),
                        const SizedBox(width: 6),
                        Text('지금 읽는 책', style: AppText.caption),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed(Routes.addBook, arguments: b),
                          child: Text(
                            '수정',
                            style: AppText.caption.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            b.title,
                            style: AppText.bodyBold.copyWith(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${b.currentPage} / ${b.totalPages}쪽', style: AppText.subLabel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 진행률 (세이지 그린)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: b.progress),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 10,
                                backgroundColor: AppColors.beige,
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${b.percent}%',
                            style: AppText.label.copyWith(color: AppColors.sageDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: b.isStarted ? '이어서 읽기' : '읽기 시작',
                      iconAsset: 'assets/svg/ic_book_open.svg',
                      onPressed: () => Navigator.of(context).pushNamed(
                        b.isStarted ? Routes.recap : Routes.timeSelect,
                      ),
                    ),
                  ],
                ),
        ),
        // 책갈피 리본
        const Positioned(
          right: 22,
          top: -4,
          child: CustomPaint(size: Size(18, 30), painter: _RibbonPainter()),
        ),
      ],
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 7)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawShadow(path, const Color(0xFF8C6633), 2, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFFF2C66D));
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height - 5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
