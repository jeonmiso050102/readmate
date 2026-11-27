# 📚 리드메이트 (ReadMate) — 완독 습관 앱

### ▶ 바로 실행해 보기: **https://readmate-79026.web.app**
설치 없이 휴대폰 · PC 브라우저에서 열고 회원가입하면 바로 쓸 수 있어요. (휴대폰에서는 「홈 화면에 추가」하면 앱처럼 사용 가능)

> 집중력을 키워 **한 권을 끝까지 읽는 경험**을 돕는 독서 앱
> 디자인씽킹(공감 → 문제정의 → 아이디어) → Figma 시안 → Flutter 구현 → 사용자 피드백 반영

**문제 정의:** 앱 사용자는 독서를 완독하기 위해 집중력 강화가 필요하다.
**HMW:** 사용자가 어떻게 집중력을 강화할 수 있을까?

---

## 주요 기능

| 아이디어 | 앱 기능 |
|---|---|
| 짧게라도 매일 읽는 습관 | 5 · 10 · 15분 타이머, 목표를 달성하면 다음 목표가 +10분 늘어남, 중간에 멈추면 「다음에 읽기」 |
| 나만의 캐릭터 책장 | 새싹이가 올라앉은 나무 책장, 쪽수에 비례한 책 두께, 책등의 세로 제목, 전체/년도별 보기, 책이 많으면 ‹ 1 / 2 › 넘겨 보기 |
| 두께 부담 줄이기 | 읽은 %만큼 불투명하게 차오르는 진행률 책 |
| 중간 회고 | 이어 읽기 전에 지난 줄거리 카드 보기 (날짜별로 쌓이고, 많으면 더보기) |
| 보상 | 완독 권수에 따라 화분 · 머그컵 · 꽃병이 열리는 책장 꾸미기 |
| 필요한 사람만 쓰는 AI 추천 | Gemini가 내 책장과 레벨을 보고 추천 → Google Books로 실제 있는 책인지 검증 → 바로 읽을 책에 추가 |
| 기타 | 이메일 회원가입/로그인, 책 추가 · 수정 · 삭제, 타이머 없이 읽은 기록 직접 입력, 다 읽은 책을 누르면 지난 기록 전체 보기 |

## 기술 스택

- **Flutter** (Dart) — Provider 상태관리, 이름 기반 라우팅, CustomPainter로 책장 · 햇살 직접 그리기
- **Firebase Authentication** — 이메일/비밀번호 로그인
- **Cloud Firestore** — 책, 독서 세션, 줄거리, 설정 실시간 저장
- **Firebase AI Logic (Gemini)** — 맞춤 책 추천 (JSON 구조화 응답, 자동 재시도 · 다른 모델로 전환)
- **Google Books API** — 추천 책 검증, 쪽수 자동 입력

## 직접 빌드해서 실행하기 (개발자용)

설치 없이 써 보려면 위의 웹 주소를 이용하세요. 코드를 직접 실행하려면 [Flutter SDK](https://docs.flutter.dev/get-started/install)가 설치되어 있어야 합니다.

```bash
git clone <이 저장소 주소>
cd readmate
flutter pub get
flutter run -d chrome --web-port 5000
```

- 실행 후 **회원가입**을 하면 빈 책장에서 시작합니다.
- AI 추천의 Google Books 키는 `http://localhost/*`에서만 동작하도록 제한되어 있어서, 꼭 `localhost`로 실행해 주세요.

## 폴더 구조

```
lib/
├── main.dart                 # 앱 시작, 화면 경로(route), 로그인 상태 확인
├── firebase_options.dart     # Firebase 연결 설정 (flutterfire configure로 생성)
├── config/api_keys.dart      # Google Books 키, Gemini 모델 이름
├── state/reading_state.dart  # 책 · 세션 · 줄거리 데이터와 Firestore 동기화
├── services/recommend_service.dart  # Gemini 추천 + Google Books 검증
├── theme/app_theme.dart      # 색상 · 글꼴
├── widgets/                  # 공통 버튼 · 카드, 책장 · 진행률 책, 줄거리 기록
└── screens/                  # 화면 17개 (아래 표)
docs/                         # 발표 자료, 앱 화면 캡처, Figma 시안
```

## 화면 구성 (Figma 시안 ↔ 코드)

| Figma 시안 | 파일 |
|---|---|
| 00 로그인 / 00 회원가입 | `login_screen.dart`, `signup_screen.dart` |
| 01 홈 · 캐릭터 책장 | `home_screen.dart`, `main_shell.dart` (하단 탭) |
| 02 책 쌓아 두기 | `add_book_screen.dart` (추가 · 수정 · 삭제) |
| 03 읽을 책 더미 | `to_read_screen.dart` |
| 04 읽기 시간 선택 | `time_select_screen.dart` |
| 05 타이머 | `timer_screen.dart` |
| 06 독서 기록 | `record_screen.dart` |
| 07 목표 달성 보상 | `reward_screen.dart` |
| 08 이어 읽기 전 회고 | `recap_screen.dart` |
| 09 완독 | `finished_screen.dart` |
| 10 책장 꾸미기 | `decorate_screen.dart` |
| 11 AI 맞춤 추천 | `recommend_screen.dart` |
| 12 수동으로 기록하기 / 13 수동 기록 완료 | `manual_record_screen.dart`, `manual_done_screen.dart` |
| (추가) 책 기록 보기 | `book_detail_screen.dart` |

## Firestore 데이터 구조와 보안 규칙

```
users/{uid}                          # 닉네임, 목표 시간, 꾸미기 설정, 지금 읽는 책
users/{uid}/books/{bookId}           # 제목, 총 쪽수, 읽은 쪽, 표지 색, 상태, 완독일
users/{uid}/books/{bookId}/summaries # 날짜별 줄거리
users/{uid}/sessions                 # 독서 세션 (날짜, 읽은 시간, 쪽수, 메모)
users/{uid}/meta/recommendations     # 저장된 AI 추천
```

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

로그인한 본인의 데이터만 읽고 쓸 수 있습니다.

## 사용자 피드백 반영

개발 중 직접 써 보며 받은 피드백 20건을 모두 반영했습니다. (자세한 표는 `docs/발표자료` 참고)
예: 고른 시간이 타이머에 반영되지 않던 문제 수정, 「지금 읽을 시간」 상자 추가, 책등 제목 · 두께 표시, 줄거리 누적 보기, 년도별 책장 보기 등
