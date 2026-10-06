# GitHub 사용 안내 — 초보자용

## GitHub는 무엇인가요?

GitHub는 소스 코드를 인터넷에 보관하고, 변경 이력을 남기며, 문제가 생기면 이전 버전으로 돌아갈 수 있게 해주는 곳입니다.

Haru에서는 하루 단위로 개발 기록을 남깁니다.

## Day 1

첫 번째 기록에는:
- Claude 기획 회의
- Xcode 프로젝트 구성
- Widget Target 오류 해결
- Claude → Gemini 전환
- Gemini 401 인증 문제 해결
- Gemini 503 문제 확인
- 재시도 로직

을 기록합니다.

## 앞으로

```
Day 1
Day 2
Day 3
...
```

형태로 개발 과정을 이어갑니다.

예:
```
Day 2 - Connect AI response to Todo
Day 2 - Fix calendar event creation
Day 3 - Improve voice input
```

## API 키 주의

다음은 GitHub에 올리지 않습니다.

```
Secrets.swift
.env
API key
password
private token
```

GitHub에 이미 올라간 키는 파일을 지워도 노출된 것으로 생각하고 폐기/재발급해야 합니다.
