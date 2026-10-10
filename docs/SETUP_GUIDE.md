# 처음 실행하기 (Mac과 Xcode)

이 안내는 Xcode를 처음 쓰는 분을 위한 순서입니다. 앱을 빌드하는 데 API 키는 필요하지 않습니다.

## 1. 프로젝트 열기

1. GitHub에서 **Code → Download ZIP**을 누르거나 저장소를 내려받습니다.
2. 압축을 풀고 `haru2.xcodeproj`를 두 번 눌러 Xcode에서 엽니다.
3. Xcode 위쪽의 실행 대상에서 `haru2`를 고릅니다.
4. 옆 기기 메뉴에서 iPhone 시뮬레이터를 고르고 ▶ 버튼을 누릅니다.

시뮬레이터는 iPhone 화면을 Mac 안에 띄우는 가상 기기입니다. 프로젝트는 iOS 26.5를 최소 버전으로 설정했습니다.

## 2. 실제 iPhone에서 실행하기

1. iPhone을 Mac에 연결하고 기기에서 이 Mac을 신뢰합니다.
2. Xcode의 기기 메뉴에서 iPhone을 고릅니다.
3. 프로젝트 설정 → **Signing & Capabilities** → `haru2`를 열고 **Team**에서 본인의 Apple 계정을 선택합니다.
4. `HaruWidgetExtension`에도 같은 Team을 선택하고 ▶를 누릅니다.

처음에는 Xcode가 서명용 설정을 만들 수 있도록 인터넷 연결이 필요할 수 있습니다. 계정이나 서명 설정 오류가 나오면 **Signing & Capabilities** 화면의 빨간 오류 안내를 확인합니다.

## 3. 홈 화면 위젯 연결하기

위젯은 앱과 별도의 작은 프로그램입니다. 두 프로그램이 같은 데이터를 보도록 **App Groups**라는 공용 공간을 연결해야 합니다.

1. Xcode에서 `haru2` Target의 **Signing & Capabilities**를 엽니다.
2. **+ Capability → App Groups**를 추가합니다.
3. `HaruWidgetExtension`에도 App Groups를 추가합니다.
4. 두 Target에서 같은 그룹 이름을 체크합니다.
5. 그 이름이 `Haru/Shared/SharedConfig.swift`의 `appGroupID`, `Haru/Haru.entitlements`, `HaruWidget/HaruWidget.entitlements`와 모두 같아야 합니다.

이 프로젝트에는 `group.com.taek.haru2`가 적혀 있습니다. 본인의 Apple 계정에서 이 이름을 사용할 수 없으면, 본인이 만든 App Group 이름으로 위 세 곳을 똑같이 바꾸세요. Xcode에서 App Groups를 저장한 뒤 앱을 한 번 실행하면 위젯에 데이터가 전달됩니다.

## 4. AI 비서 설정 (선택)

API 키는 AI 서비스의 비밀번호입니다. 저장소에 있는 `Haru/Services/APIKeyProvider.swift`는 Xcode의 실행 환경 변수에서 키를 읽습니다.

1. Xcode 메뉴 **Product → Scheme → Edit Scheme…**을 엽니다.
2. 왼쪽에서 **Run**, 위쪽에서 **Arguments**를 고릅니다.
3. **Environment Variables** 표에서 `+`를 누릅니다.
4. Name에 `GEMINI_API_KEY`, Value에 본인의 Gemini API 키를 입력합니다.
5. 이 설정을 공유 Scheme이나 GitHub에 저장하지 말고, 본인 Mac의 Run 설정에만 둡니다.

키를 설정하지 않아도 앱은 빌드되고 실행됩니다. AI 비서만 API 키가 없다는 안내를 보여줍니다. 앱스토어에 배포할 때는 앱에 키를 직접 넣지 말고 서버에서 AI 서비스에 연결하세요.

## 5. 음성 입력 권한

음성으로 입력할 때 iPhone이 마이크와 음성 인식 권한을 물어봅니다. 이 프로젝트는 권한을 요청하는 안내 문구를 포함합니다. 권한을 거부해도 글자로 입력하는 기능은 사용할 수 있습니다.

## 자주 나오는 문제

### 위젯에 “앱을 한 번 열어 주세요”가 보여요

앱과 위젯의 App Group 이름이 서로 다르거나, 앱을 아직 한 번도 실행하지 않았을 수 있습니다. 3단계의 이름을 확인하고 앱을 실행한 다음 위젯을 다시 확인하세요.

### `@main`이 여러 개라고 나와요

앱과 위젯은 각각 시작 파일이 있습니다. Xcode의 `haru2` 앱 Scheme을 선택했는지 확인하세요. `haru2`와 `HaruWidgetExtension` Scheme을 동시에 실행하려고 하지 않아도 됩니다.

### AI가 키가 없다고 해요

4단계에서 `GEMINI_API_KEY`를 Run 환경 변수로 추가했는지 확인하세요. 키를 공개 채팅이나 코드 저장소에 붙여 넣지 마세요.
