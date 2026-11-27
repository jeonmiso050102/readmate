import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

/// 날짜별로 쌓인 줄거리 기록 (최근 날짜가 위)
///
/// 처음에는 [initialCount]칸만 보여 주고, 「더보기」를 누를 때마다 [step]칸씩 더 보여 줘요.
class SummaryHistory extends StatefulWidget {
  const SummaryHistory({
    super.key,
    required this.book,
    this.initialCount = 3,
    this.step = 5,
    this.emptyText = '아직 적어 둔 줄거리가 없어요.',
    this.allowDelete = false,
  });

  final Book book;
  final int initialCount;
  final int step;
  final String emptyText;
  final bool allowDelete;

  @override
  State<SummaryHistory> createState() => _SummaryHistoryState();
}

class _SummaryHistoryState extends State<SummaryHistory> {
  late int _shown = widget.initialCount;
  Stream<List<SummaryEntry>>? _stream;
  String? _streamBookId;

  Stream<List<SummaryEntry>> _streamFor(ReadingState s) {
    // 같은 책이면 스트림을 다시 만들지 않음 (화면이 다시 그려져도 깜빡이지 않게)
    if (_stream == null || _streamBookId != widget.book.id) {
      _stream = s.summariesOf(widget.book);
      _streamBookId = widget.book.id;
      _shown = widget.initialCount;
    }
    return _stream!;
  }

  Future<void> _confirmDelete(ReadingState s, SummaryEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('이 줄거리를 지울까요?', style: AppText.bodyBold),
        content: Text('${formatKoreanDate(e.date)}에 적은 줄거리가 지워지고 되돌릴 수 없어요.',
            style: AppText.bodySub),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: AppText.label.copyWith(color: AppColors.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('지우기', style: AppText.label.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) s.deleteSummary(widget.book, e);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<ReadingState>();
    return StreamBuilder<List<SummaryEntry>>(
      stream: _streamFor(s),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }
        final entries = snap.data!;

        // 기록 칸이 아직 없고, 예전 방식으로 저장된 줄거리만 있으면 그것을 한 칸으로 보여 줌
        if (entries.isEmpty) {
          final legacy = widget.book.summary.trim();
          return legacy.isEmpty
              ? _EmptyCard(text: widget.emptyText)
              : _EntryCard(dateLabel: '이전에 적은 줄거리', pageLabel: null, text: legacy);
        }

        final visible = entries.take(_shown).toList();
        final rest = entries.length - visible.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in visible) ...[
              _EntryCard(
                dateLabel: formatKoreanDate(e.date),
                pageLabel: e.page > 0 ? '${e.page}쪽까지' : null,
                text: e.text,
                isLatest: identical(e, entries.first),
                onDelete: widget.allowDelete ? () => _confirmDelete(s, e) : null,
              ),
              const SizedBox(height: 8),
            ],
            if (rest > 0)
              _MoreButton(
                label: '더보기 ($rest개 더 있어요)',
                icon: Icons.expand_more,
                onTap: () => setState(() => _shown += widget.step),
              )
            else if (entries.length > widget.initialCount)
              _MoreButton(
                label: '접기',
                icon: Icons.expand_less,
                onTap: () => setState(() => _shown = widget.initialCount),
              ),
          ],
        );
      },
    );
  }
}

/// 줄거리 한 칸
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.dateLabel,
    required this.pageLabel,
    required this.text,
    this.isLatest = false,
    this.onDelete,
  });

  final String dateLabel;
  final String? pageLabel;
  final String text;
  final bool isLatest;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    // 왼쪽 색 띠: 가장 최근 칸은 초록, 나머지는 베이지
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 14),
            color: AppColors.card,
            child: _content(),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: isLatest ? AppColors.green : AppColors.border),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLatest ? AppColors.checkbox : AppColors.beige,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(dateLabel, style: AppText.caption.copyWith(color: AppColors.text)),
              ),
              if (pageLabel != null) ...[
                const SizedBox(width: 6),
                Text(pageLabel!, style: AppText.caption),
              ],
              if (isLatest) ...[
                const SizedBox(width: 6),
                Text('최근', style: AppText.caption.copyWith(color: AppColors.green)),
              ],
              const Spacer(),
              if (onDelete != null)
                InkResponse(
                  onTap: onDelete,
                  radius: 18,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: AppColors.subText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(text, style: AppText.body),
          ),
        ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: AppText.bodySub),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label, style: AppText.label.copyWith(color: AppColors.primary)),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.beige,
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
