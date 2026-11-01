#!/bin/bash
cd "$(dirname "$0")" || exit 1
if command -v python3 >/dev/null 2>&1; then
  python3 tool/check_build_environment.py
else
  printf '%s\n' 'Python 3을 찾지 못했습니다. 이 화면을 알려 주세요.'
fi
printf '%s\n' '확인이 끝났습니다. Enter를 누르면 닫습니다.'
read -r answer
