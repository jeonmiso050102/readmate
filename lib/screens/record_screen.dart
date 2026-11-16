import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 06 독서 기록
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Book _book = context.read<ReadingState>().current!;
  late final _page = TextEditingController(text: '${_book.currentPage}');
  late final _memo = TextEditingController(text: _book.memo);
  late final Book _preview = Book(
    title: _book.title,
    totalPages: _book.totalPages,
    color: _book.color,
    currentPage: _book.currentPage,
  );

  @override
  void initState() {
    super.initState();
    _page.addListener(() {
      final n = int.tryParse(_page.text);
      if (n != null) setState(() => _preview.currentPage = n.clamp(0, _book.totalPages));
    });
  }

  @override
  void dispose() {
    _page.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<ReadingState>();
    final page = int.parse(_page.text);
    s.recordProgress(page: page, memo: _memo.text);
    final nav = Navigator.of(context);
    if (page >= _book.totalPages) {
      nav.pushReplacementNamed(
        Routes.finished, // 09 완독
        arguments: Book(
          id: _book.id,
          title: _book.title,
          totalPages: _book.totalPages,
          color: _book.color,
          currentPage: _book.totalPages,
        ),
      );
    } else if (s.lastSessionCompleted) {
      nav.pushReplacementNamed(Routes.reward); // 07 목표 달성 보상
    } else {
      goHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = context.watch<ReadingState>().lastSessionMinutes;
    return SunScaffold(
      bottom: PrimaryButton(label: '기록하기', onPressed: _save),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('$minutes분 읽었어요!', style: AppText.title),
            const SizedBox(height: 2),
            Text('어디까지 읽었는지 남겨 주세요', style: AppText.subLabel),
            const SizedBox(height: 16),
            LabeledField(
              label: '지금 몇 쪽까지 읽었나요?',
              controller: _page,
              suffixText: '쪽 / ${_book.totalPages}쪽',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null) return '쪽수를 숫자로 입력해 주세요.';
                if (n > _book.totalPages) return '총 ${_book.totalPages}쪽보다 클 수 없어요.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ProgressBook(book: _preview),
            const SizedBox(height: 16),
            LabeledField(
              label: '내 메모',
              controller: _memo,
              hint: '기억하고 싶은 장면이나 느낌을 남겨 보세요',
              maxLines: 5,
              minLines: 4,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
