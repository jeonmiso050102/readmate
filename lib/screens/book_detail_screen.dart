import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';
import '../widgets/summary_history.dart';

/// 책 기록: 책장에 꽂힌(다 읽은) 책을 누르면 열리는 화면
///
/// 읽은 기간·총 시간, 날짜별 독서 기록, 적어 둔 줄거리 전부, 내 메모를 보여 줘요.
class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final Stream<List<ReadingSession>> _sessions =
      context.read<ReadingState>().sessionsOf(widget.book);
  int _shownSessions = 5;

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final done = b.finishedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(b.finishedAt) : null;
    final full = Book(
      id: b.id,
      title: b.title,
      totalPages: b.totalPages,
      color: b.color,
      currentPage: b.isDone ? b.totalPages : b.currentPage,
    );

    return SunScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopBar(title: '책 기록'),
          const SizedBox(height: 12),
          // 책 정보
          Row(
            children: [
              Container(
                width: 44,
                height: 64,
                decoration: BoxDecoration(
                  color: b.color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF734D26).withValues(alpha: 0.18),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title, style: AppText.heading),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${b.totalPages}쪽',
                        if (done != null) '${formatKoreanDate(done)} 완독',
                      ].join(' · '),
                      style: AppText.subLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressBook(book: full),
          const SizedBox(height: 16),

          // 독서 기록 (요약 + 날짜별)
          StreamBuilder<List<ReadingSession>>(
            stream: _sessions,
            builder: (context, snap) {
              final list = snap.data ?? const <ReadingSession>[];
              final totalMin = list.fold<int>(0, (a, e) => a + e.minutes);
              final first = list.isEmpty ? null : list.last.date;
              final visible = list.take(_shownSessions).toList();
              final rest = list.length - visible.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        _Stat(label: '총 읽은 시간', value: _minutesText(totalMin)),
                        _Stat(label: '읽은 횟수', value: '${list.length}번'),
                        _Stat(
                          label: '읽은 기간',
                          value: first == null
                              ? '-'
                              : done == null
                                  ? '${first.month}/${first.day}~'
                                  : '${first.month}/${first.day}~${done.month}/${done.day}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('독서 기록', style: AppText.label.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  if (!snap.hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    )
                  else if (list.isEmpty)
                    AppCard(child: Text('남아 있는 독서 기록이 없어요.', style: AppText.bodySub))
                  else ...[
                    for (final e in visible) ...[
                      _SessionRow(session: e),
                      const SizedBox(height: 8),
                    ],
                    if (rest > 0)
                      TextButton.icon(
                        onPressed: () => setState(() => _shownSessions += 10),
                        icon: const Icon(Icons.expand_more, size: 18, color: AppColors.primary),
                        label: Text('더보기 ($rest개 더 있어요)',
                            style: AppText.label.copyWith(color: AppColors.primary)),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.beige,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 줄거리 전부
          Text('내가 적은 줄거리', style: AppText.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          SummaryHistory(book: b, initialCount: 1000, step: 1000),
          const SizedBox(height: 20),

          // 메모
          Text('내 메모', style: AppText.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          AppCard(
            child: Text(
              b.memo.isEmpty ? '남긴 메모가 없어요.' : b.memo,
              style: b.memo.isEmpty ? AppText.bodySub : AppText.body,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _minutesText(int m) {
    if (m < 60) return '$m분';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h시간' : '$h시간 $r분';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.bodyBold),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

/// 독서 기록 한 줄: 날짜 · 시간 · 쪽 · (타이머/수동)
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});
  final ReadingSession session;

  @override
  Widget build(BuildContext context) {
    final e = session;
    final pages = e.pagesRead > 0 ? '${e.fromPage}쪽 → ${e.toPage}쪽 (${e.pagesRead}쪽)' : '쪽 변화 없음';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatKoreanDate(e.date), style: AppText.label),
                const SizedBox(height: 2),
                Text(pages, style: AppText.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.minutes}분', style: AppText.bodyBold),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: e.manual ? AppColors.beige : AppColors.checkbox,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(e.manual ? '수동 기록' : '타이머',
                    style: AppText.caption.copyWith(fontSize: 11, color: AppColors.text)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
