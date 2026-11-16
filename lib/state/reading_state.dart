import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Book {
  Book({
    required this.title,
    required this.totalPages,
    required this.color,
    this.currentPage = 0,
    this.memo = '',
    this.summary = '',
  });

  final String title;
  final int totalPages;
  final Color color;
  int currentPage;
  String memo;
  String summary;

  double get progress => totalPages == 0 ? 0 : (currentPage / totalPages).clamp(0.0, 1.0);
  int get percent => (progress * 100).round();
  bool get isStarted => currentPage > 0;
  bool get isFinished => currentPage >= totalPages;
}

enum ShelfDeco { pot, frame, lamp }

extension ShelfDecoInfo on ShelfDeco {
  String get label => switch (this) {
        ShelfDeco.pot => '작은 화분',
        ShelfDeco.frame => '액자',
        ShelfDeco.lamp => '조명',
      };
  String get asset => switch (this) {
        ShelfDeco.pot => 'assets/svg/deco_pot.svg',
        ShelfDeco.frame => 'assets/svg/deco_frame.svg',
        ShelfDeco.lamp => 'assets/svg/deco_lamp.svg',
      };
}

/// 앱 전체 독서 상태 (책장 / 읽을 책 더미 / 현재 책 / 목표 시간 / 장식)
///
/// 지금은 메모리에만 보관합니다. Firestore에 저장하려면 이 클래스의
/// 변경 메서드에서 `users/{uid}/books` 컬렉션에 쓰도록 확장하세요.
class ReadingState extends ChangeNotifier {
  ReadingState() {
    _seed();
  }

  final List<Book> shelf = []; // 완독한 책
  final List<Book> toRead = []; // 읽을 책 더미 (index 0 = 맨 위)
  Book? current;

  int goalMinutes = 15; // 이번 세션 목표
  int nextGoalMinutes = 25; // 다음 목표 (10분씩 늘리기)
  int lastSessionMinutes = 0;
  bool lastSessionCompleted = false;

  final Set<ShelfDeco> ownedDecorations = {ShelfDeco.pot, ShelfDeco.frame};
  ShelfDeco? placedDecoration = ShelfDeco.pot;
  ShelfDeco? lastReward;

  bool aiEnabled = true;
  int readerLevel = 0; // 0 초보자, 1 중급자, 2 고급자

  void _seed() {
    final c = AppColors.bookColors;
    for (var i = 0; i < 6; i++) {
      shelf.add(Book(title: '완독한 책 ${i + 1}', totalPages: 200, color: [
        c[0], c[1], c[2], c[3], AppColors.tan, c[5]
      ][i], currentPage: 200));
    }
    current = Book(
      title: '하루의 수확',
      totalPages: 300,
      color: AppColors.spine,
      currentPage: 127,
      memo: '주인공이 서점을 다시 열기로 한 장면이 좋았다.',
      summary: '주인공이 고향으로 돌아와 오래된 서점을 다시 열기로 했어요.',
    );
    toRead.addAll([
      current!,
      Book(title: '숲의 시간', totalPages: 240, color: c[1]),
      Book(title: '여름 도서관', totalPages: 312, color: c[3]),
      Book(title: '별을 세는 밤', totalPages: 188, color: c[2]),
      Book(title: '바람의 지도', totalPages: 264, color: c[4]),
    ]);
  }

  void addBook(Book book) {
    toRead.add(book);
    notifyListeners();
  }

  void selectBook(Book book) {
    current = book;
    notifyListeners();
  }

  void setGoal(int minutes) {
    goalMinutes = minutes;
    notifyListeners();
  }

  void adjustNextGoal(int delta) {
    nextGoalMinutes = (nextGoalMinutes + delta).clamp(5, 180);
    notifyListeners();
  }

  /// 타이머 종료(완료 또는 포기)
  void finishSession({required int minutes, required bool completed}) {
    lastSessionMinutes = minutes;
    lastSessionCompleted = completed;
    notifyListeners();
  }

  /// 06 독서 기록 저장
  void recordProgress({required int page, required String memo}) {
    final book = current;
    if (book == null) return;
    book.currentPage = page.clamp(0, book.totalPages);
    if (memo.trim().isNotEmpty) book.memo = memo.trim();
    if (lastSessionCompleted) {
      lastReward = ShelfDeco.pot;
      ownedDecorations.add(ShelfDeco.pot);
    }
    notifyListeners();
  }

  /// 07 보상 후 다음 목표 적용
  void applyNextGoal() {
    goalMinutes = nextGoalMinutes;
    nextGoalMinutes = goalMinutes + 10;
    notifyListeners();
  }

  /// 09 완독 → 책장에 꽂기
  void shelveCurrent() {
    final book = current;
    if (book == null) return;
    toRead.remove(book);
    if (!shelf.contains(book)) shelf.add(book);
    current = toRead.isNotEmpty ? toRead.first : null;
    notifyListeners();
  }

  void placeDecoration(ShelfDeco? d) {
    placedDecoration = d;
    notifyListeners();
  }

  void setAiEnabled(bool v) {
    aiEnabled = v;
    notifyListeners();
  }

  void setReaderLevel(int v) {
    readerLevel = v;
    notifyListeners();
  }
}
