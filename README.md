# 하루 (Haru) — 일정 · 할 일 · AI 비서 · 일기장 앱

이 저장소는 Haru 앱의 1일차 개발 기록과 Swift/SwiftUI 소스를 보관합니다.

## Day 1에서 한 일
- Claude와 초기 제품 기획 회의
- SwiftUI 기본 앱 구조 구성
- 로그인, 오늘, 캘린더, AI 비서, 일기장, 음성 입력, 위젯 구조 준비
- Xcode에서 `@main` 중복 오류 확인 및 앱/Widget Extension Target 분리
- Claude API에서 Google Gemini API로 전환
- Gemini 401 인증 오류 해결
- Gemini 503 과부하 응답 확인
- 429/500/502/503/504 같은 일시 오류에 대한 재시도 로직 적용
- API 키가 GitHub에 올라가지 않도록 비밀 파일 분리

## 초보자용 문서
- [1일차 개발 기록](docs/DAY1_LOG.md)
- [초기 기획 회의록](docs/TEAM_MEETING.md)
- [Xcode 설정 안내](docs/SETUP_GUIDE.md)
- [GitHub 사용 안내](docs/GITHUB_UPLOAD.md)

## 주의
`Secrets.swift` 같은 실제 API 키 파일은 GitHub에 올리지 않습니다. `Secrets.example.txt`를 참고해 로컬에서 설정합니다.

## 현재 상태
Day 1의 목표는 앱에서 Gemini API까지 요청이 정상적으로 도착하는 단계까지 확인하는 것이었습니다. 다음 단계에서 Gemini 응답을 실제 일정/할 일 데이터에 연결합니다.
