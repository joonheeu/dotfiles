#!/bin/sh

# ================================
# 도움말 출력
# ================================
show_help() {
  cat <<EOF
🔐 Password Generator

Usage:
  genpass [options] [preset|length] [length]

Presets:
  standard    Uppercase + Lowercase + Numbers (default: 24)
  token       Uppercase + Lowercase + Numbers + Special (default: 32)

Options:
  -u, --uppercase    Include uppercase letters (A-Z)
  -l, --lowercase    Include lowercase letters (a-z)
  -n, --number       Include numbers (0-9)
  -s, --special      Include special characters (_ -)
  -a, --all          Include all character sets
  -h, --help         Show this help message

Examples:
  genpass                          # Standard preset (24 chars)
  genpass standard                 # Standard preset (24 chars)
  genpass token                    # Token preset (32 chars)
  genpass 50                       # Default combination, 50 chars
  genpass --lowercase --number 12  # Lowercase + numbers, 12 chars
  genpass standard 64              # Standard preset, 64 chars
  genpass -ulns 24                 # All options, 24 chars
  genpass -a 32                    # All options, 32 chars

EOF
}

# ================================
# 기본값 설정
# ================================
USE_UPPER=0
USE_LOWER=0
USE_DIGIT=0
USE_SPECIAL=0
LENGTH=""
PRESET=""
SILENT=0

# ================================
# 옵션 파싱
# ================================
ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -u|--uppercase)
      USE_UPPER=1
      shift
      ;;
    -l|--lowercase)
      USE_LOWER=1
      shift
      ;;
    -n|--number)
      USE_DIGIT=1
      shift
      ;;
    -s|--special)
      USE_SPECIAL=1
      shift
      ;;
    -a|--all)
      USE_UPPER=1
      USE_LOWER=1
      USE_DIGIT=1
      USE_SPECIAL=1
      shift
      ;;
    -ulns|-uln|-uls|-uns|-lns|-ul|-un|-us|-ln|-ls|-ns)
      # 축약형 옵션 처리
      case "$1" in
        *u*) USE_UPPER=1 ;;
      esac
      case "$1" in
        *l*) USE_LOWER=1 ;;
      esac
      case "$1" in
        *n*) USE_DIGIT=1 ;;
      esac
      case "$1" in
        *s*) USE_SPECIAL=1 ;;
      esac
      shift
      ;;
    standard|token)
      PRESET="$1"
      shift
      ;;
    [0-9]*)
      # 숫자로 시작하는 경우 길이로 처리
      if [ -z "$LENGTH" ]; then
        LENGTH="$1"
      fi
      shift
      ;;
    *)
      echo "❌ Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# ================================
# 프리셋 처리
# ================================
if [ -n "$PRESET" ]; then
  case "$PRESET" in
    standard)
      USE_UPPER=1
      USE_LOWER=1
      USE_DIGIT=1
      USE_SPECIAL=0
      [ -z "$LENGTH" ] && LENGTH=24
      ;;
    token)
      USE_UPPER=1
      USE_LOWER=1
      USE_DIGIT=1
      USE_SPECIAL=1
      [ -z "$LENGTH" ] && LENGTH=32
      ;;
  esac
elif [ "$USE_UPPER" -eq 0 ] && [ "$USE_LOWER" -eq 0 ] && [ "$USE_DIGIT" -eq 0 ] && [ "$USE_SPECIAL" -eq 0 ]; then
  # 옵션이 없고 프리셋도 없으면 standard 기본값
  USE_UPPER=1
  USE_LOWER=1
  USE_DIGIT=1
  USE_SPECIAL=0
  [ -z "$LENGTH" ] && LENGTH=24
fi

# ================================
# 길이 검증
# ================================
if [ -z "$LENGTH" ]; then
  echo "❌ Length is required" >&2
  echo "Use --help for usage information" >&2
  exit 1
fi

# 숫자인지 확인
if ! [ "$LENGTH" -eq "$LENGTH" ] 2>/dev/null || [ "$LENGTH" -le 0 ]; then
  echo "❌ Invalid length: $LENGTH" >&2
  exit 1
fi

# ================================
# 문자셋 구성
# ================================
CHARSET=""

[ "$USE_UPPER" -eq 1 ] && CHARSET="${CHARSET}A-Z"
[ "$USE_LOWER" -eq 1 ] && CHARSET="${CHARSET}a-z"
[ "$USE_DIGIT" -eq 1 ] && CHARSET="${CHARSET}0-9"
[ "$USE_SPECIAL" -eq 1 ] && CHARSET="${CHARSET}_-"

if [ -z "$CHARSET" ]; then
  echo "❌ No character set selected" >&2
  exit 1
fi

# ================================
# 비밀번호 생성
# ================================
# 특수문자 사용 시 앞/뒤에 - 또는 _가 오지 않도록 제한
if [ "$USE_SPECIAL" -eq 1 ]; then
  # 앞/뒤에 사용할 수 있는 문자셋 (특수문자 제외)
  SAFE_CHARSET=""
  [ "$USE_UPPER" -eq 1 ] && SAFE_CHARSET="${SAFE_CHARSET}A-Z"
  [ "$USE_LOWER" -eq 1 ] && SAFE_CHARSET="${SAFE_CHARSET}a-z"
  [ "$USE_DIGIT" -eq 1 ] && SAFE_CHARSET="${SAFE_CHARSET}0-9"
  
  if [ -z "$SAFE_CHARSET" ]; then
    # 안전한 문자가 없으면 특수문자도 허용 (최소한의 경우)
    PASSWORD=$(LC_ALL=C tr -dc "$CHARSET" </dev/urandom | head -c "$LENGTH")
  elif [ "$LENGTH" -eq 1 ]; then
    # 길이가 1이면 안전한 문자만 사용
    PASSWORD=$(LC_ALL=C tr -dc "$SAFE_CHARSET" </dev/urandom | head -c 1)
  elif [ "$LENGTH" -eq 2 ]; then
    # 길이가 2면 둘 다 안전한 문자
    PASSWORD=$(LC_ALL=C tr -dc "$SAFE_CHARSET" </dev/urandom | head -c 2)
  else
    # 앞/뒤는 안전한 문자, 중간은 전체 문자셋 사용
    first_char=$(LC_ALL=C tr -dc "$SAFE_CHARSET" </dev/urandom | head -c 1)
    last_char=$(LC_ALL=C tr -dc "$SAFE_CHARSET" </dev/urandom | head -c 1)
    middle=$(LC_ALL=C tr -dc "$CHARSET" </dev/urandom | head -c $((LENGTH - 2)))
    PASSWORD="${first_char}${middle}${last_char}"
  fi
else
  PASSWORD=$(LC_ALL=C tr -dc "$CHARSET" </dev/urandom | head -c "$LENGTH")
fi

# ================================
# 출력 / 복사
# ================================
printf '%s' "$PASSWORD" | pbcopy

if [ "$SILENT" -eq 0 ]; then
  echo
  echo "✅ Generated Password:"
  printf '%s\n' "$PASSWORD"
fi

echo "📋 Copied to clipboard"
