import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';
import 'manual_record_screen.dart';

/// 13 수동 기록 완료
class ManualDoneScreen extends StatelessWidget {
  const ManualDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = ModalRoute.of(context)?.settings.arguments as ManualRecordResult?;
    if (r == null) return const SizedBox.shrink();
    final diff = r.toPage - r.fromPage;
    return SunScaffold(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlineButtonX(
            label: '타이머로 이어 읽기',
            onPressed: () {
              context.read<ReadingState>().selectBook(r.book);
              Navigator.of(context).pushReplacementNamed(Routes.timeSelect);
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: '홈으로', onPressed: () => goHome(context)),
        ],
      ),
      body: Column(
        children: [
          const Sprout(mood: SproutMood.happy, width: 156),
          const SizedBox(height: 12),
          Text('기록했어요!', style: AppText.title),
          const SizedBox(height: 12),
          Text('${r.book.title} · ${formatKoreanDate(r.date).split(' (').first}',
              style: AppText.subLabel),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('읽은 시간', style: AppText.subLabel)),
                    Text('${r.minutes}분', style: AppText.bodyBold),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text('읽은 쪽', style: AppText.subLabel)),
                    Text(
                      '${r.fromPage}쪽 → ${r.toPage}쪽 (${diff >= 0 ? diff : 0}쪽)',
                      style: AppText.bodyBold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ProgressBook(book: r.book),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.beige,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '수동 기록은 독서 시간과 진도에 반영돼요. 책장 장식은 타이머로 목표를 달성했을 때 받을 수 있어요.',
              style: AppText.body,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
