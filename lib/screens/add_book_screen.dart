import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 02 책 쌓아 두기
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key, this.initialTitle, this.initialPages});
  final String? initialTitle;
  final int? initialPages;

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle ?? '');
  late final _pages = TextEditingController(text: widget.initialPages?.toString() ?? '');
  int _color = 0;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    _pages.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ReadingState>().addBook(Book(
          title: _title.text.trim(),
          totalPages: int.parse(_pages.text),
          color: AppColors.bookColors[_color],
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewTitle = _title.text.trim().isEmpty ? '책 제목' : _title.text.trim();
    final previewPages = _pages.text.isEmpty ? '0쪽' : '${_pages.text}쪽';
    return SunScaffold(
      bottom: PrimaryButton(label: '읽을 책 더미에 쌓기', onPressed: _submit),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: '책 쌓아 두기'),
            const SizedBox(height: 18),
            Row(
              children: [
                const Sprout(width: 84),
                const SizedBox(width: 8),
                Expanded(child: Text('어떤 책을 읽을까요?', style: AppText.heading)),
              ],
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: '책 제목',
              controller: _title,
              hint: '예) 하루의 수확',
              textInputAction: TextInputAction.next,
              validator: (v) => (v?.trim().isEmpty ?? true) ? '책 제목을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: '총 쪽수',
              controller: _pages,
              hint: '예) 300',
              suffixText: '쪽',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return '쪽수를 숫자로 입력해 주세요.';
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text('표지 색', style: AppText.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              children: [
                for (var i = 0; i < AppColors.bookColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.bookColors[i],
                        shape: BoxShape.circle,
                        border: i == _color
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('이렇게 쌓여요', style: AppText.label),
            const SizedBox(height: 8),
            StackedBook(
              title: previewTitle,
              trailing: previewPages,
              color: AppColors.bookColors[_color],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
