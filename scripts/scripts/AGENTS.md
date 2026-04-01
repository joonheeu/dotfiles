# ~/scripts — Agent 운영 지침

이 폴더는 macOS 터미널에서 사용하는 커스텀 스크립트 모음입니다.
에이전트가 스크립트를 생성·수정·삭제할 때 이 지침을 따르세요.

---

## 폴더 구조

```
~/scripts/
├── mac/        # macOS 시스템 관리 (정리, 설정, 하드웨어 제어)
├── dev/        # 개발 도구 (에디터, 빌드, 코드 보조)
├── security/   # 보안/인증 (비밀번호, 시크릿, 키체인)
├── claude/     # Claude/AI 관련 (skills, 에이전트 보조)
└── AGENTS.md   # 이 파일
```

> `tmp-*.py`, `exp-*.py` 임시 파일은 루트에 두지 않습니다.
> 임시 스크립트가 필요하면 해당 카테고리 폴더에 `tmp-` 접두사로 생성하고, 완료 후 삭제하세요.

---

## 카테고리 분류 기준

| 폴더 | 포함 기준 | 예시 |
|------|-----------|------|
| `mac/` | macOS 전용 기능, 시스템 설정, 스토리지 관리 | `cleanup_mac_storage.sh`, `enable_dictation.sh` |
| `dev/` | 에디터·IDE 도구, 개발 환경 보조 | `editor-clean-extension` |
| `security/` | 비밀번호 생성, 환경변수 시크릿, 키체인 | `genpass`, `secret_env.sh` |
| `claude/` | Claude Code 보조, skills 관리, AI 자동화 | `skills-check.sh` |

새 카테고리가 필요한 경우: 기존 4개 중 어디에도 속하지 않을 때만 폴더를 신설하고, 이 문서의 표를 업데이트하세요.

---

## 파일 명명 규칙

### 확장자 없는 실행 파일 (권장)
터미널에서 이름만으로 바로 실행되어야 하는 스크립트는 **확장자 없이** 생성합니다.

```
security/genpass          # genpass 로 바로 실행
dev/editor-clean-extension
```

### .sh 확장자 파일
- 직접 실행보다 **내부 로직 파일**로 사용되거나, alias로만 호출되는 경우
- `command_not_found_handler` 덕분에 확장자 없이도 터미널에서 실행 가능합니다
  - 예: `skills-check` → `claude/skills-check.sh` 자동 탐색

### .py 확장자 파일
- Python 스크립트는 `.py` 유지
- 진입점이 필요하면 같은 이름의 확장자 없는 wrapper 파일을 함께 만드세요

```bash
# dev/editor-clean-extension (wrapper)
#!/bin/bash
python3 "$(dirname "$0")/editor-clean-extension.py" "$@"
```

---

## 실행 권한

직접 실행되는 파일은 반드시 실행 권한을 부여하세요.

```bash
chmod +x ~/scripts/<category>/<script-name>
```

`.sh` 파일은 `command_not_found_handler`가 `zsh`로 실행하므로 권한이 없어도 동작하지만,
확장자 없는 파일은 실행 권한이 필수입니다.

---

## Shebang 가이드

| 언어 | Shebang |
|------|---------|
| bash | `#!/usr/bin/env bash` |
| zsh | `#!/usr/bin/env zsh` |
| sh (POSIX) | `#!/bin/sh` |
| python3 | `#!/usr/bin/env python3` |

- `#!/bin/bash`보다 `#!/usr/bin/env bash`를 선호합니다 (경로 독립적)
- zsh 전용 기능이 필요한 경우에만 `#!/usr/bin/env zsh` 사용

---

## PATH 및 미들웨어 동작 방식

`~/.zshrc`에 다음 두 가지 메커니즘이 적용되어 있습니다.

### 1. 서브디렉토리 자동 PATH 등록
```zsh
for _scripts_dir in "$HOME/scripts"/*/; do
  PATH="$_scripts_dir:$PATH"
done
```
→ 새 폴더를 추가하면 `.zshrc` 수정 없이 자동으로 PATH에 포함됩니다.

### 2. command_not_found_handler
```zsh
command_not_found_handler() {
  # <cmd>.sh 파일을 모든 서브디렉토리에서 탐색하여 실행
}
```
→ `skills-check` 입력 시 `claude/skills-check.sh`를 자동으로 찾아 실행합니다.

### 3. `s` 미들웨어 함수
```zsh
s                      # 전체 목록 카테고리별 출력
s genpass              # 이름으로 검색 후 실행
s security genpass     # 카테고리 지정 실행
```

---

## 새 스크립트 생성 체크리스트

1. **카테고리 결정** — 위 표에서 적합한 폴더 선택
2. **파일 생성** — 올바른 shebang 포함
3. **실행 권한** — `chmod +x` 적용 (직접 실행 파일인 경우)
4. **`.zshrc` 수정 불필요** — PATH 자동 등록 및 `command_not_found_handler`로 커버됨
5. **alias 필요 시** — `~/.zshrc`의 alias 섹션에 `~/scripts/<cat>/<name>` 경로로 추가
6. **이 문서 업데이트** — 카테고리가 바뀌거나 신규 폴더 생성 시

---

## 금지 사항

- `~/scripts/` 루트에 직접 스크립트 파일 생성 금지 (서브디렉토리 사용)
- 시크릿·API 키를 스크립트 내에 하드코딩 금지 → `secret_env.sh` 또는 환경변수 사용
- 프로덕션 시스템에 직접 영향을 주는 스크립트는 `--dry-run` 옵션 포함 권장
