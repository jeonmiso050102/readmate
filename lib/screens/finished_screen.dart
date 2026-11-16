import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 09 완독
class FinishedScreen extends StatelessWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    // '책장에 꽂기' 직후에는 current가 바뀌므로, 화면이 닫히는 동안에는 마지막으로 꽂은 책을 보여 줌
    final book = s.current ?? (s.shelf.isNotEmpty ? s.shelf.last : null);
    if (book == null) return const SizedBox.shrink();
    // 미리 보기: 기존 책장 + 방금 다 읽은 책
    final preview = [...s.shelf, if (!s.shelf.contains(book)) book];
    return SunScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: '책장에 꽂기',
            onPressed: () {
              s.shelveCurrent();
              goHome(context);
            },
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: '다음 책 고르기',
            onPressed: () {
              s.shelveCurrent();
              goHome(context, tab: 1);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text('한 권을 끝까지 읽었어요!', style: AppText.title, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('${book.title} · ${book.totalPages}쪽 완독', style: AppText.subLabel),
          const SizedBox(height: 12),
          ProgressBook(book: book),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: CharacterShelf(
              books: preview,
              decoration: s.placedDecoration,
              highlightLast: true,
              bubble: '내가 꽂아 둘게!',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
