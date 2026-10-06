# Haru Xcode 설정 안내

## 1. 앱 Target과 Widget Target은 다릅니다

Haru에는 두 실행 대상이 있습니다.

**Haru**
- 실제 iPhone 앱
- 시작점: `HaruApp.swift`

**HaruWidget**
- 홈 화면/잠금 화면 위젯
- 시작점: `HaruWidget.swift`

두 파일 모두 `@main`을 가지므로 같은 Target에 넣으면 안 됩니다.

## 2. Target Membership

Xcode에서 Swift 파일을 선택하고 오른쪽 File Inspector의 **Target Membership**을 확인합니다.

기본 규칙:

```
HaruApp.swift
☑ Haru
☐ HaruWidget

HaruWidget.swift
☐ Haru
☑ HaruWidget

WidgetSnapshot.swift
☑ Haru
☑ HaruWidget
```

## 3. Gemini API 키

로컬에 `Secrets.swift`를 만들고 다음처럼 사용합니다.

```swift
enum Secrets {
    static let geminiAPIKey = "내_Gemini_API_키"
}
```

**중요: 이 파일은 GitHub에 올리지 않습니다.**

## 4. 실행 순서

1. Xcode에서 프로젝트를 엽니다.
2. Scheme에서 Haru 앱을 선택합니다.
3. iPhone 또는 Simulator를 선택합니다.
4. ▶ 실행합니다.
5. 오류가 나오면 오류 메시지를 그대로 기록합니다.

## 5. `@main` 오류가 나오면

```
'main' attribute can only apply to one type in a module
```

오류가 나오면 가장 먼저 Target Membership을 확인합니다.

대부분 앱의 `@main`과 위젯의 `@main`이 같은 Target에 들어간 경우입니다.
