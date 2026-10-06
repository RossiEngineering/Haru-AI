# Haru — Day 1 개발 기록

## 1. 시작: Claude 기획 회의

처음 Haru는 Claude에게 제품 기획 회의를 요청하는 방식으로 출발했습니다.

회의에서 정한 핵심 방향:
- 첫 화면은 **오늘**: 오늘 일정 + 오늘 할 일
- 하단 탭: **오늘 · 캘린더 · AI 비서 · 일기장**
- 음성은 iPhone 음성 인식으로 텍스트화한 뒤 AI 비서와 같은 흐름으로 처리
- 홈/잠금 화면 위젯 지원
- 초기 로그인은 서버 없이 기기 안에서 동작
- 초보자도 이해할 수 있도록 파일마다 역할을 설명
- API 키는 GitHub에 올리지 않음

자세한 회의 내용은 `TEAM_MEETING.md`에 기록했습니다.

## 2. SwiftUI 기본 구조

다음 기능의 뼈대를 만들었습니다.
- 로그인/회원가입
- 오늘 화면
- 월간 캘린더
- 일정 추가
- 할 일
- 일기장
- 음성 입력
- AI 비서
- 홈/잠금 화면 위젯

## 3. Xcode에서 발생한 `@main` 오류

오류:
```
'main' attribute can only apply to one type in a module
```

원인은 앱의 `HaruApp.swift`와 위젯의 `HaruWidget.swift`가 같은 Target에 들어간 것이었습니다.

해결:
- `HaruApp.swift` → Haru 앱 Target
- `HaruWidget.swift` → HaruWidget Extension Target
- `WidgetSnapshot.swift` → 양쪽 Target

즉 앱과 위젯이 서로 다른 실행 모듈이 되도록 Target Membership을 분리했습니다.

## 4. Claude → Gemini 전환

사용자가 Google Gemini를 사용하기로 결정했습니다.

AI 통신부를:
```
Haru → Claude API
```
에서
```
Haru → Gemini API
```
로 변경했습니다.

Gemini REST API의 `generateContent` 요청과 `x-goog-api-key` 인증 방식을 사용합니다.

## 5. Gemini 401 인증 오류

처음에는 다음 오류가 발생했습니다.

```
Gemini 서버 오류 (401)
Request had invalid authentication credentials.
Expected OAuth 2 access token, login cookie or other valid authentication credential.
```

API 키를 삭제하고 새로 만들어 다시 적용했고, 이후 401 오류는 사라졌습니다.

## 6. Gemini 503 오류

새 키로 실행한 뒤 다음 오류가 발생했습니다.

```
Gemini 서버 오류 (503)
This model is currently experiencing high demand.
Spikes in demand are usually temporary.
Please try again later.
```

401은 인증 문제였지만 503은 Gemini 서버가 일시적으로 바쁜 상황입니다.

그래서 `AIAssistantService.swift`에 429/500/502/503/504 같은 일시 오류를 잠시 기다렸다가 재시도하는 로직을 넣었습니다.

## 7. Day 1 결과

완료:
- Claude 기획 회의
- SwiftUI 기본 구조
- 로그인/오늘/캘린더/일기/음성/위젯 구조
- Widget Target 분리
- `@main` 오류 원인 파악 및 해결
- Claude → Gemini 전환
- Gemini 인증 문제 해결
- 일시적인 서버 오류 재시도
- API 키 비밀 파일 분리

다음 단계:
- Gemini 응답을 실제 `AIAction`으로 변환
- `add_event` / `add_todo`를 실제 데이터에 연결
- 음성 → Gemini → 일정 생성 전체 테스트
- Widget App Group 최종 확인
- 배포 전 API 키 서버화
