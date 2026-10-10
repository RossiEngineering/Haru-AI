# 프로젝트 파일 안내

처음에는 앱 전체를 이해하려고 하지 않아도 됩니다. 바꾸고 싶은 화면이나 기능과 연결된 파일만 찾아보면 됩니다.

## 폴더를 쉽게 비유하면

| 위치 | 하는 일 | 예시 |
|---|---|---|
| `Haru/Views/` | 사용자가 보는 화면 | 오늘, 달력, AI 채팅, 일기장, 설정 |
| `Haru/Models/` | 앱이 다루는 정보의 설계도 | 일정, 할 일, 일기 |
| `Haru/Services/` | 화면 뒤에서 처리하는 일 | AI 연결, 로그인, 알림, 위젯 데이터 |
| `Haru/Shared/` | 앱과 위젯이 함께 읽는 정보 | 오늘 할 일과 일정 요약 |
| `HaruWidget/` | 홈 화면과 잠금 화면 위젯 | 위젯에 오늘 일정을 표시 |
| `docs/` | 사람이 읽는 설명서와 기록 | 실행 방법, 개발 기록 |

## 자주 찾는 파일

| 파일 | 쉬운 설명 |
|---|---|
| `Haru/HaruApp.swift` | 앱이 시작될 때 가장 먼저 준비하는 곳 |
| `Haru/Views/MainTabView.swift` | 화면 좌우 넘기기와 아래쪽 메뉴 |
| `Haru/Views/Today/TodayView.swift` | 오늘 날짜, 일정, 할 일 화면 |
| `Haru/Views/Components/TodoRow.swift` | 할 일 한 줄과 오른쪽 완료 체크박스 |
| `Haru/Views/Calendar/CalendarView.swift` | 달력과 날짜별 일정 화면 |
| `Haru/Views/AI/AIChatView.swift` | AI 채팅 입력, 응답, 음성 입력 |
| `Haru/Views/Diary/DiaryListView.swift` | 일기 목록 화면 |
| `Haru/Views/Settings/SettingsView.swift` | 배경 사진, 알림, 언어, AI 동의 설정 |
| `Haru/Services/AppSettings.swift` | 앱에서 저장해 두는 설정 이름과 기본값 |
| `Haru/Services/AIAssistantService.swift` | AI에 요청을 보내고 답을 처리 |
| `Haru/Services/WidgetSyncService.swift` | 앱의 오늘 정보를 위젯 쪽으로 전달 |
| `Haru/Services/BriefingService.swift` | 아침·저녁 알림 만들기 |
| `Haru/Services/APIKeyProvider.swift` | Xcode 실행 환경에서 AI 키 읽기 |
| `Haru/Shared/WidgetSnapshot.swift` | 앱과 위젯이 주고받는 오늘 요약 |
| `Haru/Shared/SharedConfig.swift` | 앱과 위젯이 함께 쓰는 App Group 이름 |
| `HaruWidget/HaruWidget.swift` | 위젯에 실제로 그려지는 화면 |
| `haru2.xcodeproj` | Xcode가 어떤 파일을 앱과 위젯으로 빌드할지 정하는 프로젝트 |

## 화면을 고치는 순서

1. 고치려는 화면 파일을 `Haru/Views/`에서 찾습니다.
2. 화면을 그리는 코드를 바꿉니다.
3. Xcode에서 `haru2` Scheme을 골라 빌드합니다.
4. 위젯 데이터를 바꿨다면 `Haru/Shared/`와 `HaruWidget/`도 함께 확인합니다.

Xcode 프로젝트 안의 **Target**은 각각 따로 빌드되는 프로그램입니다. 이 앱에는 iPhone 앱 Target과 위젯 Target이 있습니다. `HaruApp.swift`는 앱에서, `HaruWidget.swift`는 위젯에서 시작하므로 같은 Target에 넣으면 안 됩니다.
