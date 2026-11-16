import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 08 이어 읽기 전 회고
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final book = context.watch<ReadingState>().current!;
    return SunScaffold(
      bottom: PrimaryButton(
        label: '이어서 읽기',
        onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.timeSelect),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopBar(title: '이어 읽기 전 회고'),
          const SizedBox(height: 12),
          const SproutWithBubble(text: '여기까지 읽었어!'),
          const SizedBox(height: 12),
          Text('지난번엔 ${book.currentPage}쪽까지 읽었어요', style: AppText.heading),
          const SizedBox(height: 12),
          Text('지금까지의 줄거리와 내가 남긴 메모를 다시 살펴봐요', style: AppText.bodySub),
          const SizedBox(height: 12),
          ProgressBook(book: book),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지금까지의 줄거리', style: AppText.label.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  book.summary.isEmpty ? '아직 줄거리 요약이 없어요.' : book.summary,
                  style: AppText.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 메모', style: AppText.label.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(book.memo.isEmpty ? '남긴 메모가 없어요.' : book.memo, style: AppText.body),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
