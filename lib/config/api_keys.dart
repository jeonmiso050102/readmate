/// 외부 API 설정
///
/// Google Books API 키 만드는 법 (무료, 하루 1,000회):
/// 1. https://console.cloud.google.com 에서 Firebase와 같은 프로젝트(Readmate)를 선택
/// 2. API 및 서비스 → 라이브러리 → "Books API" 검색 → 사용
/// 3. API 및 서비스 → 사용자 인증 정보 → 사용자 인증 정보 만들기 → API 키
/// 4. 만든 키의 "API 제한사항"을 Books API로, "애플리케이션 제한사항"을
///    웹사이트(http://localhost:*/* 와 나중에 배포할 주소)로 제한하는 것을 권장
/// 5. 아래 따옴표 안에 키를 붙여 넣기
const String kGoogleBooksApiKey = 'AIzaSyCyfccwItxjC-Oj-VRdviWq-Rav8VBEwJk';

/// Firebase AI Logic(Gemini Developer API)에서 쓸 모델
/// 무료(Spark 요금제)로 쓸 수 있는 안정 버전 모델
const String kGeminiModel = 'gemini-3.8-flash';

/// 기본 모델이 바쁘거나 응답이 늦을 때(503) 대신 쓸 가벼운 모델 (무료)
const String kGeminiFallbackModel = 'gemini-3.5-flash-lite';
