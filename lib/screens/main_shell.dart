import 'package:flutter/material.dart';

import '../widgets/book_widgets.dart';
import 'home_screen.dart';
import 'recommend_screen.dart';
import 'to_read_screen.dart';

/// 하단 탭바가 있는 화면 묶음: 0 책장(01) / 1 읽을 책(03) / 2 추천(11)
final shellTab = ValueNotifier<int>(0);

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) {
        return Scaffold(
          // 떠 있는 둥근 하단 바 뒤로 배경이 이어지게
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: index,
            children: const [HomeScreen(), ToReadScreen(), RecommendScreen()],
          ),
          bottomNavigationBar: BottomTabBar(
            index: index,
            onTap: (i) => shellTab.value = i,
          ),
        );
      },
    );
  }
}
