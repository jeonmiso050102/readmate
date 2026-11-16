import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/reading_state.dart';
import '../theme/app_theme.dart';
import '../widgets/book_widgets.dart';
import '../widgets/common.dart';

/// 02 책 쌓아 두기 / 책 정보 수정
///
/// [editing]이 있으면 수정 모드로 열려요. (라우트 arguments로 Book을 넘기면 됨)
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key, this.editing});
  final Book? editing;

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Book? _editing = widget.editing;
  late final _title = TextEditingController(text: _editing?.title ?? '');
  late final _pages = TextEditingController(text: _editing?.totalPages.toString() ?? '');
  late final _readPages = TextEditingController(text: _editing?.currentPage.toString() ?? '0');
  late int _color = _initialColorIndex();
  bool _saving = false;

  bool get _isEdit => _editing != null;

  int _initialColorIndex() {
    final c = _editing?.color;
    if (c == null) return 0;
    final i = AppColors.bookColors.indexWhere((x) => x.toARGB32() == c.toARGB32());
    return i < 0 ? 0 : i;
  }

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
    _readPages.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<ReadingState>();
    final title = _title.text.trim();
    final total = int.parse(_pages.text);
    final color = AppColors.bookColors[_color];
    setState(() => _saving = true);
    // 저장 요청만 보내고 바로 닫아요. (Firestore가 화면에 즉시 반영하고, 서버 저장은 뒤에서 진행)
    if (_isEdit) {
      final read = int.parse(_readPages.text);
      s.updateBook(
        _editing!,
        title: title,
        totalPages: total,
        color: color,
        currentPage: read,
      );
      // 읽은 쪽이 총 쪽수에 닿으면(100%) 타이머 없이도 09 완독 화면으로
      final ed = _editing!;
      if (read >= total && !ed.isDone) {
        s.selectBook(ed);
        Navigator.of(context).pushReplacementNamed(
          Routes.finished,
          arguments: Book(
            id: ed.id,
            title: title,
            totalPages: total,
            color: color,
            currentPage: total,
          ),
        );
        return;
      }
    } else {
      s.addBook(title: title, totalPages: total, color: color);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? '책 정보를 수정했어요' : '「$title」을(를) 읽을 책 더미에 쌓았어요')),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('이 책을 삭제할까요?', style: AppText.bodyBold),
        content: Text('「${_editing!.title}」의 진도와 메모도 함께 삭제되고 되돌릴 수 없어요.',
            style: AppText.bodySub),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: AppText.label.copyWith(color: AppColors.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제', style: AppText.label.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<ReadingState>().deleteBook(_editing!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewTitle = _title.text.trim().isEmpty ? '책 제목' : _title.text.trim();
    final previewPages = _pages.text.isEmpty ? '0쪽' : '${_pages.text}쪽';
    return SunScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: _isEdit ? '수정 완료' : '읽을 책 더미에 쌓기',
            loading: _saving,
            onPressed: _submit,
          ),
          if (_isEdit) ...[
            const SizedBox(height: 4),
            GhostButton(label: '이 책 삭제하기', onPressed: _delete),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopBar(title: _isEdit ? '책 정보 수정' : '책 쌓아 두기'),
            const SizedBox(height: 18),
            Row(
              children: [
                const Sprout(width: 84),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEdit ? '바뀐 정보를 알려 주세요' : '어떤 책을 읽을까요?',
                    style: AppText.heading,
                  ),
                ),
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
            if (_isEdit) ...[
              const SizedBox(height: 18),
              LabeledField(
                label: '지금까지 읽은 쪽',
                controller: _readPages,
                suffixText: '쪽',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  final total = int.tryParse(_pages.text) ?? 0;
                  if (n == null) return '쪽수를 숫자로 입력해 주세요.';
                  if (n > total) return '총 쪽수($total쪽)보다 클 수 없어요.';
                  return null;
                },
              ),
            ],
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
