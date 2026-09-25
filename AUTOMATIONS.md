# 홈 자동화 운영 대장

이 문서는 `~/.dotfiles`가 관리하는 홈 환경 자동화의 **목록과 운영 기준**입니다.
새 항목을 만들거나 기존 항목을 예약 실행하기 전에 이 문서와 `scripts/AGENTS.md`를
읽습니다. 원본 스크립트는 `scripts/`에만 두고, `~/scripts` 심볼릭 링크를 통해 실행합니다.

## 공통 정책

| 등급 | 기준 | 실행·예약 원칙 |
| --- | --- | --- |
| A — 점검 | 상태를 읽고 보고만 함 | 수동·예약 모두 가능 |
| B — 제한된 정리 | 재생 가능하고 대상이 좁음 | 기본 dry-run, `--apply` 필요; 예약은 사용자 승인 후 |
| C — 영향 있음 | 프로세스·로컬 파일·캐시를 변경 | 수동 확인을 기본으로 함 |
| D — 파괴적/민감 | 광범위 삭제, 인증·권한·시크릿, 외부 시스템 변경 | 자동 예약 금지; 대상·복구 방법을 확인한 뒤 별도 승인 |

모든 새 자동화는 다음을 갖춰야 합니다.

- 목적과 대상 경로를 코드와 이 문서에 명시
- 기본은 점검 또는 dry-run, 실제 변경은 `--apply`·확인 프롬프트 등으로 분리
- 실패 시 0이 아닌 종료 코드와 이해 가능한 오류 메시지
- 가능한 경우 `--help`, 사전 조건 검사, 실행 로그 또는 결과 요약
- 시크릿 값을 읽거나 출력하지 않음. `.ssh`, 실제 `.env*`, Keychain은 기본 범위 밖

## 등록된 자동화

| 이름 | 위치 | 등급 | 기본 동작 | 예약 상태 | 후속 조치 |
| --- | --- | --- | --- | --- | --- |
| dotfiles-prune | `scripts/system/dotfiles-prune` | B | 오래된 백업·zcompdump·저장소 내부 `.DS_Store`를 dry-run으로 표시 | 미등록 | 한 달 이상 dry-run 결과를 검토한 뒤 필요하면 `--install-schedule` |
| home-automation-status | `scripts/system/home-automation-status` | A | 링크·의존성·Git 상태·LaunchAgent 등록 상태 보고 | 미등록 | 변경 또는 새 장비 설정 뒤 실행 |
| codex-imagegen | `scripts/ai/codex-imagegen` | C | 작업 공간 내부에 이미지 생성; Codex CLI 필요 | 미등록 | 사용 빈도와 출력 관리 방식을 결정한 뒤 유지 여부 검토 |
| kill-port | `scripts/system/kill-port` | C | 포트를 점검하고 사용자 확인 뒤 프로세스 종료 | 미등록 | 예약하지 않음 |

## 레거시 보류 항목

아래 파일은 광범위한 삭제 또는 환경 의존 경로를 포함합니다. 현재 어떤 LaunchAgent에도
등록하지 않았으며, **재작성·dry-run·대상 제한을 마치기 전에는 실행하거나 예약하지 않습니다.**

| 파일 | 보류 이유 | 처리 기준 |
| --- | --- | --- |
| `scripts/system/cleanup-daily.sh` | 캐시·Docker 이미지/컨테이너를 광범위하게 삭제 | 필요 기능만 안전한 새 명령으로 분리 |
| `scripts/system/cleanup-light.sh` | `/tmp`, 홈 전체의 끊어진 심볼릭 링크를 삭제 | 대상과 보존 기간을 좁힌 뒤 재검토 |
| `scripts/system/cleanup-weekly.sh` | `node_modules`, pip cache, Downloads, Docker 이미지를 삭제 | 프로젝트·다운로드 삭제 정책을 먼저 결정 |
| `scripts/system/cleanup-monthly.sh` | 시스템 로그와 휴지통을 비가역적으로 삭제 | 사용자별 보존 정책을 정한 뒤 재검토 |

## 새 자동화 추가 절차

1. `scripts/AGENTS.md`의 분류에 따라 위치와 이름을 결정합니다.
2. 위 등급을 정하고, C·D라면 사용자가 허용한 정확한 대상과 복구 방법을 먼저 확인합니다.
3. 사전 조건 검사와 `--help`를 구현하고, 변경 작업은 dry-run/`--apply`로 분리합니다.
4. 문법 검사와 dry-run을 실행합니다. 실제 변경 검증은 승인된 최소 대상에서만 합니다.
5. 이 표에 등록하고 `home-automation-status`에 필요한 점검을 추가합니다.
6. 예약 실행은 수동 사용과 로그 검토 후에만 도입합니다. macOS는 LaunchAgent를 사용하고,
   Ubuntu 서버는 systemd user timer 또는 해당 서버의 운영 방식에 맞는 별도 유닛을 둡니다.
7. dotfiles 변경은 관련 파일만 별도 커밋하고, 실행 명령·검증 결과·남은 위험을 기록합니다.

## 정기 점검

- 새 자동화 추가 뒤: `~/scripts/system/home-automation-status`
- 월 1회: `~/scripts/system/dotfiles-prune`의 dry-run 결과 검토
- 분기 1회: 이 표의 예약 상태와 레거시 보류 항목을 검토
- 새 Mac 또는 서버: `~/.dotfiles/install.sh` 실행 후 상태 점검. 패키지 설치는 아직 별도 단계이므로,
  필요한 명령이 없으면 해당 자동화의 사전 조건을 확인
