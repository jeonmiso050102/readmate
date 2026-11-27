import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/common.dart';
import '../widgets/summary_history.dart';

export '../utils/date_format.dart';


/// 13 화면으로 넘길 기록 결과
class ManualRecordResult {
  const ManualRecordResult({
    required this.book,
    required this.date,
    required this.minutes,
    required this.fromPage,
    required this.toPage,
  });
  final Book book; // 기록이 반영된 상태의 책
  final DateTime date;
  final int minutes;
  final int fromPage;
  final int toPage;
}

/// 12 수동으로 기록하기
class ManualRecordScreen extends StatefulWidget {
  const ManualRecordScreen({super.key});

  @override
  State<ManualRecordScreen> createState() => _ManualRecordScreenState();
}

class _ManualRecordScreenState extends State<ManualRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _bookId = context.read<ReadingState>().current?.id;
  DateTime _date = DateTime.now();
  int _minutes = 20;
  late final _page = TextEditingController(
    text: '${context.read<ReadingState>().current?.currentPage ?? 0}',
  );
  // 줄거리는 기록할 때마다 새 칸으로 쌓이므로 빈 칸에서 시작
  final _summary = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    _summary.dispose();
    super.dispose();
  }

  Book? _selected(ReadingState s) {
    for (final b in s.toRead) {
      if (b.id == _bookId) return b;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final s = context.read<ReadingState>();
    final book = _selected(s);
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('읽은 책을 골라 주세요.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final to = int.parse(_page.text);
    final from = book.currentPage;
    s.recordManual(
      book: book,
      date: _date,
      minutes: _minutes,
      toPage: to,
      summary: _summary.text,
    );

    final updated = Book(
      id: book.id,
      title: book.title,
      totalPages: book.totalPages,
      color: book.color,
      currentPage: to,
    );
    final nav = Navigator.of(context);
    if (to >= book.totalPages) {
      // 100% 달성 → 09 완독
      s.selectBook(book);
      nav.pushReplacementNamed(Routes.finished, arguments: updated);
    } else {
      nav.pushReplacementNamed(
        Routes.manualDone,
        arguments: ManualRecordResult(
          book: updated,
          date: _date,
          minutes: _minutes,
          fromPage: from,
          toPage: to,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReadingState>();
    final books = s.toRead;
    final book = _selected(s);
    return SunScaffold(
      bottom: PrimaryButton(label: '기록하기', onPressed: books.isEmpty ? null : _save),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: '수동으로 기록하기'),
            const SizedBox(height: 12),
            const SproutWithBubble(text: '타이머를 깜빡해도 괜찮아!', sproutWidth: 84),
            const SizedBox(height: 12),
            // 읽은 책
            Text('읽은 책', style: AppText.label),
            const SizedBox(height: 6),
            _FieldBox(
              child: books.isEmpty
                  ? Text('읽을 책 더미에 책을 먼저 추가해 주세요', style: AppText.bodySub)
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: book?.id,
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: AppColors.card,
                        hint: Text('책을 골라 주세요', style: AppText.bodySub),
                        style: AppText.bodyBold,
                        items: [
                          for (final b in books)
                            DropdownMenuItem(value: b.id, child: Text(b.title)),
                        ],
                        onChanged: (id) {
                          setState(() {
                            _bookId = id;
                            final picked = books.firstWhere((b) => b.id == id);
                            _page.text = '${picked.currentPage}';
                          });
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // 읽은 날짜
            Text('읽은 날짜', style: AppText.label),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: _FieldBox(
                child: Row(
                  children: [
                    Expanded(child: Text(formatKoreanDate(_date), style: AppText.bodyBold)),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.subText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 얼마나 읽었나요?
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('얼마나 읽었나요?', style: AppText.label),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoundStep(
                        label: '−',
                        onTap: () => setState(() => _minutes = (_minutes - 5).clamp(5, 600)),
                      ),
                      Expanded(
                        child: Center(child: Text('$_minutes분', style: AppText.title)),
                      ),
                      _RoundStep(
                        label: '+',
                        onTap: () => setState(() => _minutes = (_minutes + 5).clamp(5, 600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: '몇 쪽까지 읽었나요?',
              controller: _page,
              suffixText: book == null ? '쪽' : '쪽 / ${book.totalPages}쪽',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null) return '쪽수를 숫자로 입력해 주세요.';
                if (book != null && n > book.totalPages) {
                  return '총 ${book.totalPages}쪽보다 클 수 없어요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: '이번에 읽은 부분의 줄거리',
              controller: _summary,
              hint: '이번에 읽은 내용을 짧게 정리해 보세요.\n날짜별로 쌓여서 다음에 이어 읽기 전에 다시 보여 드려요.',
              maxLines: 6,
              minLines: 4,
            ),
            if (book != null) ...[
              const SizedBox(height: 16),
              Text('지난 줄거리', style: AppText.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              SummaryHistory(book: book, initialCount: 2),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 입력 칸 모양의 상자 (#FFFBEF, 테두리 #EFD8B4)
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: child,
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.beige,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Text(label, style: AppText.heading)),
        ),
      ),
    );
  }
}
