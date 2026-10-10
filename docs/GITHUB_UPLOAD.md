# GitHub에 변경 올리기 (초보자용)

GitHub는 코드의 인터넷 보관함입니다. **commit**은 변경 내용을 이름 붙여 저장하는 것이고, **push**는 내 Mac의 commit을 GitHub에 올리는 것입니다.

## GitHub Desktop으로 올리기

1. GitHub Desktop에서 이 저장소를 엽니다.
2. 왼쪽 아래 Changes 목록에서 올릴 파일을 확인합니다.
3. `Secrets.swift`, API 키, 개인 비밀번호가 목록에 있으면 올리지 않습니다.
4. 아래 Summary에 `오늘 화면의 이동과 위젯을 개선`처럼 변경 내용을 적습니다.
5. **Commit to main**을 누르고, 이어서 **Push origin**을 누릅니다.

## 터미널로 올리기

저장소 폴더에서 아래 명령을 한 줄씩 실행합니다.

```bash
git status
git add .gitignore README.md docs Haru HaruWidget haru2.xcodeproj haru2Tests haru2UITests
git commit -m "docs: 사용 안내와 앱 기능 정리"
git push
```

`git status`는 올릴 파일을 미리 확인하는 명령입니다. 파일을 모두 한꺼번에 추가하는 `git add .`보다, 올릴 폴더를 직접 적는 편이 처음에는 안전합니다.

## API 키는 올리지 마세요

API 키는 서비스에 로그인하는 비밀번호와 같습니다. 이 프로젝트는 키를 Xcode의 Run 환경 변수에 입력하도록 되어 있습니다. 다음 항목은 GitHub에 올리면 안 됩니다.

```text
GEMINI_API_KEY 값
Secrets.swift
.env 파일
개인 인증서와 비밀번호
```

키가 GitHub에 한 번이라도 올라갔다면 파일만 삭제하지 말고, 해당 서비스에서 기존 키를 폐기하고 새 키를 발급해야 합니다.
