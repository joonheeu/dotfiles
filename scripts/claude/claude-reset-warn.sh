#!/usr/bin/env zsh
# claude-reset-warn.sh — Claude 사용량 리셋 타이밍 경고 wrapper
# 마지막 실행 후 5시간 이상 경과 + 리셋 후 30분 이상 지났을 경우 경고 및 진행 여부 확인

claude_last_run() {
  local LAST_RUN_FILE="$HOME/.claude_last_run"
  local NOW LAST_RUN ELAPSED SINCE_RESET MINS RH RM
  NOW=$(date +%s)

  if [[ -f "$LAST_RUN_FILE" ]]; then
    LAST_RUN=$(cat "$LAST_RUN_FILE")
    ELAPSED=$(( NOW - LAST_RUN ))

    if (( ELAPSED >= 18000 )); then          # 5시간(18000초) 이상 → 리셋 발생
      SINCE_RESET=$(( ELAPSED % 18000 ))     # 현재 사이클에서 리셋 후 경과 초
      MINS=$(( SINCE_RESET / 60 ))

      if (( MINS >= 30 )); then              # 30분 이상 늦은 시작
        RH=$(( (300 - MINS) / 60 ))
        RM=$(( (300 - MINS) % 60 ))
        echo "⚠️  ${MINS}m gone, ${RH}h ${RM}m left until reset" >&2
        local REPLY
        read -k 1 "REPLY?   Proceed? [y/N] " </dev/tty
        echo >&2
        [[ "$REPLY" != [yY] ]] && return 0
      fi
    fi
  fi

  echo "$NOW" > "$LAST_RUN_FILE"
  command claude_last_run "$@"
}

