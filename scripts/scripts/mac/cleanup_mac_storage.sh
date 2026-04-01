#!/bin/bash
# Mac 저장공간 정리 스크립트 (안전한 항목만)
# 실행: ~/scripts/cleanup_mac_storage.sh
# 레이아웃 검사만: ~/scripts/cleanup_mac_storage.sh --check-home-layout

set -euo pipefail

TMP_TTL_DAYS="${TMP_TTL_DAYS:-7}"

usage() {
  echo "사용법: $(basename "$0") [옵션]"
  echo "  (인자 없음)  캐시·Cursor 로그 정리 + ~/tmp ${TMP_TTL_DAYS}일 초과 파일 삭제"
  echo "  --check-home-layout  홈 루트 규약 위반 항목만 출력하고 종료"
  echo "  --help               이 도움말"
  echo "환경변수: TMP_TTL_DAYS (기본 7) — ~/tmp 파일 보관 일수"
}

is_allowed_home_root_entry() {
  local n="$1"
  case "$n" in
    Desktop|Documents|Downloads|Library|Movies|Music|Pictures|Public) return 0 ;;
    go|workspace|scripts|tmp|logs|Projects|moneroocean|sketchup) return 0 ;;
    "Download Archive") return 0 ;;
    "Screen Studio Projects") return 0 ;;
    "Photos Library.photoslibrary") return 0 ;;
  esac
  # iCloud … Drive(아카이브) — 폴더명에 일반 공백 대신 NBSP(U+00A0)가 들어갈 수 있음
  if [[ "$n" =~ ^iCloud.Drive\(아카이브\)$ ]]; then
    return 0
  fi
  return 1
}

check_home_layout() {
  echo "=== 홈 루트 규약 점검 ($HOME) ==="
  echo "허용 목록은 ~/.ai/docs/home-layout.md 와 동기화하세요."
  echo ""
  local violations=0
  local path base
  while IFS= read -r -d '' path; do
    base=$(basename "$path")
    if is_allowed_home_root_entry "$base"; then
      continue
    fi
    echo "· $base"
    violations=$((violations + 1))
  done < <(find "$HOME" -maxdepth 1 -mindepth 1 ! -name '.*' -print0)

  echo ""
  if [[ "$violations" -eq 0 ]]; then
    echo "홈 루트: 허용 목록 밖 항목 없음."
  else
    echo "총 ${violations}개 항목이 규약 밖입니다. 이동·정리 후 다시 실행하세요."
  fi
}

cleanup_tmp_ttl() {
  [[ -d "$HOME/tmp" ]] || return 0
  local tmpfiles
  tmpfiles=$(find "$HOME/tmp" -type f -mtime "+${TMP_TTL_DAYS}" 2>/dev/null | wc -l | tr -d ' ')
  find "$HOME/tmp" -type f -mtime "+${TMP_TTL_DAYS}" -delete 2>/dev/null || true
  find "$HOME/tmp" -type d -empty -delete 2>/dev/null || true
  echo "✓ ~/tmp 에서 ${TMP_TTL_DAYS}일 초과 파일 정리 (삭제 대상 파일 수: ${tmpfiles})"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--check-home-layout" ]]; then
  check_home_layout
  exit 0
fi

echo "=== Mac 저장공간 정리 시작 ==="

# 1. Cursor 로그 (약 1.7GB) - 앱 재시작 시 자동 재생성
if [ -d "/Users/daniel/Library/Application Support/Cursor/logs" ]; then
  rm -rf "/Users/daniel/Library/Application Support/Cursor/logs"/*
  echo "✓ Cursor 로그 삭제 완료 (~1.7GB)"
fi

# 2. Cursor 캐시 (CachedData, GPUCache - 약 450MB)
for dir in "CachedData" "GPUCache"; do
  p="/Users/daniel/Library/Application Support/Cursor/$dir"
  if [ -d "$p" ]; then
    rm -rf "$p"/*
    echo "✓ Cursor $dir 삭제 완료"
  fi
done

# 3. 사용자 캐시 (약 2.9GB 중 상당 부분 - 앱이 필요 시 다시 만듦)
rm -rf ~/Library/Caches/ms-playwright 2>/dev/null && echo "✓ Playwright 캐시 삭제 (~1.5GB)" || true
rm -rf ~/Library/Caches/company.thebrowser.Browser 2>/dev/null && echo "✓ The Browser 캐시 삭제 (~1.2GB)" || true
rm -rf ~/Library/Caches/Arc 2>/dev/null && echo "✓ Arc 캐시 삭제" || true
rm -rf ~/Library/Caches/node-gyp 2>/dev/null && echo "✓ node-gyp 캐시 삭제" || true

# 4. ~/tmp TTL
cleanup_tmp_ttl

# 5. 휴지통 비우기 (Finder에서 비우거나)
echo ""
echo "휴지통은 Finder에서 ⌘+Shift+Delete 로 비우세요."
echo ""
echo "=== 정리 완료 ==="
df -h / | tail -1
