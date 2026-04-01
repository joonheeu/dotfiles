#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# secret_env.sh — macOS Keychain 기반 시크릿 관리
#
# 보안 설계:
#   - security dump-keychain 미사용 (전체 keychain 복호화 방지)
#   - 키 이름 인덱스를 별도 파일로 관리 (~/.config/secret_env/keys)
#   - eval 안전성: 모든 에러/안내 메시지는 stderr로 출력
#   - CLI 인자 value 전달 지원하되 경고 표시 (ps 노출 위험)
# ---------------------------------------------------------------------------

INDEX_DIR="${SECRET_ENV_INDEX_DIR:-$HOME/.config/secret_env}"
INDEX_FILE="$INDEX_DIR/keys"

_ensure_index() {
  if [[ ! -d "$INDEX_DIR" ]]; then
    mkdir -p "$INDEX_DIR"
    chmod 700 "$INDEX_DIR"
  fi
  if [[ ! -f "$INDEX_FILE" ]]; then
    touch "$INDEX_FILE"
    chmod 600 "$INDEX_FILE"
  fi
}

_index_add() {
  local key="$1"
  _ensure_index
  if ! grep -qxF "$key" "$INDEX_FILE" 2>/dev/null; then
    echo "$key" >> "$INDEX_FILE"
  fi
}

_index_remove() {
  local key="$1"
  _ensure_index
  if [[ -f "$INDEX_FILE" ]]; then
    local tmp
    tmp="$(mktemp)"
    grep -vxF "$key" "$INDEX_FILE" > "$tmp" || true
    mv "$tmp" "$INDEX_FILE"
    chmod 600 "$INDEX_FILE"
  fi
}

_index_list() {
  local prefix="${1:-}"
  _ensure_index
  if [[ ! -s "$INDEX_FILE" ]]; then
    return 0
  fi
  if [[ -n "$prefix" ]]; then
    grep "^${prefix}" "$INDEX_FILE" | sort -u || true
  else
    sort -u "$INDEX_FILE" || true
  fi
}

usage() {
  cat <<'EOF' >&2
사용법:
  secret set <KEY> [VALUE]          # VALUE 생략 시 안전한 프롬프트 입력
  secret set --stdin <KEY>          # stdin에서 읽기
  secret get <KEY>                  # 값 출력 (stdout)
  secret list [PREFIX]              # 저장된 키 목록
  secret ls [PREFIX]                # list 별칭
  secret load [KEY_OR_PREFIX]       # eval "$(secret load KEY)" 형식으로 사용
  secret exists <KEY>               # 존재 여부 확인 (exit 0/1)
  secret delete <KEY>               # 삭제
  secret rm <KEY>                   # delete 별칭
  secret export <KEY> [ENV_NAME]    # export 문 출력
  secret run <KEY> [ENV_NAME] -- <cmd...>  # 환경변수 주입 후 명령 실행
  secret doctor                     # 환경 점검

eval 사용 예시:
  eval "$(secret load COOLIFY_TOKEN)"
  eval "$(secret load OPENAI_)"     # 프리픽스로 여러 키 한번에 로드
EOF
}

require_key() {
  if [[ "${1:-}" == "" ]]; then
    echo "오류: KEY가 필요합니다." >&2
    usage
    exit 1
  fi
}

keychain_get() {
  local key="$1"
  security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null
}

cmd_set() {
  local mode="${1:-}"
  local key
  local value=""

  if [[ "$mode" == "--stdin" ]]; then
    key="${2:-}"
    require_key "$key"
    value="$(cat)"
  else
    key="$mode"
    require_key "$key"
    if [[ "${2:-}" != "" ]]; then
      echo "경고: CLI 인자로 전달된 값은 'ps aux'에 잠깐 노출될 수 있습니다." >&2
      echo "       안전하게 저장하려면 값 없이 실행하세요 (프롬프트 입력)." >&2
      value="${2}"
    fi
  fi

  if [[ -z "$value" ]]; then
    read -r -s -p "$key 값을 입력하세요: " value </dev/tty
    echo >&2
  fi

  if [[ -z "$value" ]]; then
    echo "오류: 빈 값은 저장할 수 없습니다." >&2
    exit 1
  fi

  security add-generic-password -U -a "$USER" -s "$key" -w "$value" >/dev/null
  _index_add "$key"
  echo "저장됨: $key" >&2
}

cmd_list() {
  local prefix="${1:-}"
  local result
  result="$(_index_list "$prefix")"

  if [[ -z "$result" ]]; then
    if [[ -n "$prefix" ]]; then
      echo "목록 없음 (prefix: $prefix)" >&2
    else
      echo "목록 없음" >&2
      echo "힌트: secret set <KEY> 로 먼저 저장하세요." >&2
    fi
    return 0
  fi

  printf '%s\n' "$result"
}

cmd_get() {
  local key="$1"
  local value
  if ! value="$(keychain_get "$key")"; then
    echo "오류: Keychain에서 '$key'를 찾지 못했습니다." >&2
    exit 1
  fi
  printf '%s\n' "$value"
}

cmd_exists() {
  local key="$1"
  if keychain_get "$key" >/dev/null 2>&1; then
    echo "exists" >&2
    exit 0
  fi
  echo "missing" >&2
  exit 1
}

cmd_delete() {
  local key="$1"
  if security delete-generic-password -a "$USER" -s "$key" >/dev/null 2>&1; then
    _index_remove "$key"
    echo "삭제됨: $key" >&2
  else
    echo "삭제할 항목 없음: $key" >&2
  fi
}

cmd_export() {
  local key="$1"
  local env_name="${2:-$key}"
  local value
  if ! value="$(keychain_get "$key")"; then
    echo "오류: Keychain에서 '$key'를 찾지 못했습니다." >&2
    exit 1
  fi
  printf 'export %s=%q\n' "$env_name" "$value"
}

cmd_load() {
  local query="${1:-}"
  local keys=()
  local found_keys

  if [[ -z "$query" ]]; then
    # 인자 없이 load 호출: 안전 거부
    echo "오류: 'secret load'는 KEY 또는 PREFIX가 필요합니다." >&2
    echo "       예: eval \"\$(secret load COOLIFY_TOKEN)\"" >&2
    echo "           eval \"\$(secret load OPENAI_)\"" >&2
    exit 1
  fi

  # 정확한 키 이름으로 먼저 시도
  if keychain_get "$query" >/dev/null 2>&1; then
    printf 'export %s=%q\n' "$query" "$(keychain_get "$query")"
    return 0
  fi

  # 프리픽스 매칭
  found_keys="$(_index_list "$query")"
  if [[ -z "$found_keys" ]]; then
    echo "오류: '$query'에 해당하는 키를 찾지 못했습니다." >&2
    exit 1
  fi

  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    local value
    if value="$(keychain_get "$key" 2>/dev/null)"; then
      printf 'export %s=%q\n' "$key" "$value"
    else
      echo "경고: '$key' 값을 keychain에서 읽지 못했습니다. (인덱스와 불일치)" >&2
    fi
  done <<< "$found_keys"
}

cmd_run() {
  require_key "${1:-}"
  local key="$1"
  shift

  local env_name="$key"
  if [[ "${1:-}" != "--" && "${1:-}" != "" ]]; then
    env_name="$1"
    shift
  fi

  if [[ "${1:-}" != "--" ]]; then
    echo "오류: run 명령은 '--' 뒤에 실행할 명령이 필요합니다." >&2
    usage
    exit 1
  fi
  shift

  if [[ $# -eq 0 ]]; then
    echo "오류: 실행할 명령이 비어 있습니다." >&2
    exit 1
  fi

  local value
  if ! value="$(keychain_get "$key")"; then
    echo "오류: Keychain에서 '$key'를 찾지 못했습니다." >&2
    exit 1
  fi

  env "$env_name=$value" "$@"
}

cmd_doctor() {
  local ok=true

  # security 명령 확인
  if command -v security &>/dev/null; then
    echo "✅ security: $(command -v security)" >&2
  else
    echo "❌ security 명령을 찾지 못했습니다." >&2
    ok=false
  fi

  # login keychain 확인
  local keychain_path
  if keychain_path="$(security login-keychain 2>/dev/null | tr -d '"' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"; then
    echo "✅ login keychain: $keychain_path" >&2
  else
    echo "❌ login keychain 경로 확인 실패" >&2
    ok=false
  fi

  # 인덱스 파일 확인
  _ensure_index
  local key_count
  key_count="$(wc -l < "$INDEX_FILE" | tr -d ' ')"
  echo "✅ 인덱스: $INDEX_FILE ($key_count 개 키)" >&2

  # 인덱스 vs keychain 동기화 확인
  local missing=0
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    if ! keychain_get "$key" >/dev/null 2>&1; then
      echo "⚠️  인덱스에는 있지만 keychain에 없음: $key" >&2
      ((missing++)) || true
    fi
  done < "$INDEX_FILE"

  if [[ $missing -gt 0 ]]; then
    echo "힌트: 'secret rm <KEY>' 로 인덱스를 정리하세요." >&2
  fi

  echo "----" >&2
  cmd_list
  $ok
}

cmd_migrate_index() {
  # 기존에 dump-keychain 방식으로 저장된 키를 인덱스로 마이그레이션
  echo "인덱스 파일이 비어 있거나 없습니다. Keychain에서 '$USER' 계정의 항목을 스캔합니다..." >&2
  echo "⚠️  이 작업은 macOS 접근 허용 팝업이 나타날 수 있습니다." >&2

  local keychain_path
  keychain_path="$(security login-keychain 2>/dev/null | tr -d '"' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

  local found=0
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    _index_add "$key"
    echo "  인덱스 추가: $key" >&2
    ((found++)) || true
  done < <(security dump-keychain "$keychain_path" 2>/dev/null \
    | awk -v user="$USER" '
      function flush() {
        if (in_item && has_acct && has_svce && acct == user) print svce
        in_item=0; has_acct=0; has_svce=0; acct=""; svce=""
      }
      /^class: "genp"/ { flush(); in_item=1; next }
      /^class: "/      { flush(); next }
      in_item && /"acct"<blob>=/ {
        sub(/.*"acct"<blob>="/, ""); sub(/".*/, ""); acct=$0; has_acct=1
      }
      in_item && /"svce"<blob>=/ {
        sub(/.*"svce"<blob>="/, ""); sub(/".*/, ""); svce=$0; has_svce=1
      }
      END { flush() }
    ' | sort -u)

  echo "마이그레이션 완료: $found 개 키" >&2
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    set)            cmd_set "$@" ;;
    list|ls)        cmd_list "${1:-}" ;;
    get)            require_key "${1:-}"; cmd_get "$1" ;;
    exists)         require_key "${1:-}"; cmd_exists "$1" ;;
    delete|rm)      require_key "${1:-}"; cmd_delete "$1" ;;
    export)         require_key "${1:-}"; cmd_export "$@" ;;
    load)           cmd_load "${1:-}" ;;
    run)            cmd_run "$@" ;;
    doctor)         cmd_doctor ;;
    migrate-index)  cmd_migrate_index ;;
    -h|--help|help) usage ;;
    *)
      echo "알 수 없는 명령: $cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
