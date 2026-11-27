import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 01 홈 · 캐릭터 책장
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final book = s.current;
    return SunScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('내 책장', style: AppText.title),
                    Text('완독한 책 ${s.shelf.length}권', style: AppText.subLabel),
                  ],
                ),
              ),
              Material(
                color: AppColors.card,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => Navigator.of(context).pushNamed(Routes.decorate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/svg/ic_deco.svg', width: 18, height: 18),
                        const SizedBox(width: 4),
                        Text('꾸미기', style: AppText.label.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CharacterShelf(
            books: s.shelf,
            decoration: s.placedDecoration,
            bubble: '오늘도 조금 더!',
            // 다 읽은 책을 누르면 그 책의 독서 기록·줄거리 보기
            onBookTap: (b) => Navigator.of(context).pushNamed(Routes.bookDetail, arguments: b),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: book == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('지금 읽는 책이 없어요', style: AppText.bodyBold),
                      const SizedBox(height: 4),
                      Text('읽고 싶은 책을 쌓아 두고 새싹이와 함께 읽어 봐요', style: AppText.bodySub),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: '첫 책 추가하기',
                        onPressed: () => Navigator.of(context).pushNamed(Routes.addBook),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('지금 읽는 책', style: AppText.caption),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context)
                                          .pushNamed(Routes.addBook, arguments: book),
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
                                Text(book.title, style: AppText.bodyBold),
                              ],
                            ),
                          ),
                          Text('${book.currentPage} / ${book.totalPages}쪽',
                              style: AppText.subLabel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: book.progress,
                          minHeight: 8,
                          backgroundColor: AppColors.beige,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: book.isStarted ? '이어서 읽기' : '읽기 시작',
                        onPressed: () => Navigator.of(context).pushNamed(
                          book.isStarted ? Routes.recap : Routes.timeSelect,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
