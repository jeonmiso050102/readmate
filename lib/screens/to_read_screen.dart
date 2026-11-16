import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 03 읽을 책 더미
class ToReadScreen extends StatelessWidget {
  const ToReadScreen({super.key});

  // 책 더미가 삐뚤빼뚤 쌓여 보이도록 하는 너비 비율 (시안 300/316/292/332/308 ÷ 345)
  static const _widthRatios = [0.87, 0.916, 0.846, 0.962, 0.893];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final books = s.toRead;
    return SunScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlineButtonX(
            label: '책 추가하기',
            onPressed: () => Navigator.of(context).pushNamed(Routes.addBook),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: '읽기 시작',
            onPressed: s.current == null
                ? null
                : () => Navigator.of(context).pushNamed(
                      s.current!.isStarted ? Routes.recap : Routes.timeSelect,
                    ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('앞으로 읽을 책', style: AppText.title),
          Text('다 읽으면 책장으로 옮겨져요', style: AppText.subLabel),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            return Column(
              children: [
                const SizedBox(height: 6),
                const Sprout(mood: SproutMood.sleep, width: 120),
                const SizedBox(height: 3),
                if (s.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else if (books.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('아직 쌓아 둔 책이 없어요.\n아래 「책 추가하기」로 첫 책을 쌓아 보세요!',
                        style: AppText.bodySub, textAlign: TextAlign.center),
                  ),
                for (var i = 0; i < books.length; i++) ...[
                  StackedBook(
                    title: books[i].title,
                    trailing: books[i].isStarted
                        ? '${books[i].currentPage}/${books[i].totalPages}쪽'
                        : '${books[i].totalPages}쪽',
                    color: books[i].color,
                    width: c.maxWidth * _widthRatios[i % _widthRatios.length],
                    selected: s.isCurrent(books[i]),
                    // 한 번 누르면 이번에 읽을 책으로 선택, 선택된 책을 다시 누르면 정보 수정
                    onTap: () {
                      if (s.isCurrent(books[i])) {
                        Navigator.of(context).pushNamed(Routes.addBook, arguments: books[i]);
                      } else {
                        s.selectBook(books[i]);
                      }
                    },
                    onLongPress: () =>
                        Navigator.of(context).pushNamed(Routes.addBook, arguments: books[i]),
                  ),
                  const SizedBox(height: 3),
                ],
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.tan,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          if (books.isNotEmpty)
            Text('책을 눌러 이번에 읽을 책을 고르고, 고른 책을 한 번 더 누르면 정보를 수정할 수 있어요',
                style: AppText.caption),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
