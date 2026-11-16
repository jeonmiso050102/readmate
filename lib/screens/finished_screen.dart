import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 09 완독
class FinishedScreen extends StatefulWidget {
  const FinishedScreen({super.key});

  @override
  State<FinishedScreen> createState() => _FinishedScreenState();
}

class _FinishedScreenState extends State<FinishedScreen> {
  // 화면을 연 순간의 책을 기억해 둠 ('책장에 꽂기' 후 current가 다음 책으로 바뀌어도 그대로 보이게)
  late final Book? _book = () {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final b = arg is Book ? arg : context.read<ReadingState>().current;
    if (b == null) return null;
    return Book(
      id: b.id,
      title: b.title,
      totalPages: b.totalPages,
      color: b.color,
      currentPage: b.totalPages,
      isDone: true,
    );
  }();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final book = _book;
    if (book == null) return const SizedBox.shrink();
    // 미리 보기: 기존 책장 + 방금 다 읽은 책
    final preview = [...s.shelf.where((b) => b.id != book.id), book];
    return SunScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: '책장에 꽂기',
            onPressed: () {
              s.shelveBook(book);
              goHome(context);
            },
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: '다음 책 고르기',
            onPressed: () {
              s.shelveBook(book);
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
