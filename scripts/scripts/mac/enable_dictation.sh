#!/bin/bash

# 이 스크립트는 macOS의 디테이션(받아쓰기) 기능을 강제로 활성화합니다.
# launchd로 ~/Library/LaunchAgents/com.user.dictationfix.plist에서 실행 가능하며,
# Dictation이 비활성화되는 문제를 자동으로 복구하는 데 사용할 수 있습니다.

# Dictation 활성화
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMMasterDictationEnabled -bool true
