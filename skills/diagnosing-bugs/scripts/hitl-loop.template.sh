#!/usr/bin/env bash
# Human-in-the-loop reproduction loop.
# Copy this file, edit the steps below, and run it.
# The agent runs the script; the user follows prompts in their terminal.
#
# Usage:
#   bash hitl-loop.template.sh
#
# Two helpers:
#   step "<instruction>"          → show instruction, wait for Enter
#   capture VAR "<question>"      → show question, read response into VAR
#
# At the end, captured values are printed as KEY=VALUE for the agent to parse.
#
# 在地化偏離上游：上游的 read 未防護，使用者按 Ctrl-D（或非互動 stdin）時 read 回傳非零，
# 被 `set -e` 直接中止腳本，已收集的回答全部丟失、`--- Captured ---` 不會印出。
# 下方加了 EOF 防護與 EXIT trap，確保無論如何結束都印出已收集到的值。

set -euo pipefail

ABORTED=0

step() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [Enter when done] " _ || ABORTED=1
}

capture() {
  local var="$1" question="$2" answer=''
  printf '\n>>> %s\n' "$question"
  read -r -p "    > " answer || ABORTED=1
  printf -v "$var" '%s' "$answer"
}

# --- edit below ---------------------------------------------------------
# 每個 capture 的變數先給預設空值，這樣 set -u 下即使中途中斷也能印出。

ERRORED=''
ERROR_MSG=''

report() {
  printf '\n--- Captured ---\n'
  printf 'ERRORED=%s\n' "$ERRORED"
  printf 'ERROR_MSG=%s\n' "$ERROR_MSG"
  [ "$ABORTED" -eq 1 ] && printf 'ABORTED=1  # stdin 提早結束，以上為中斷前收集到的值\n'
  return 0
}
trap report EXIT

step "Open the app at http://localhost:3000 and sign in."

capture ERRORED "Click the 'Export' button. Did it throw an error? (y/n)"

capture ERROR_MSG "Paste the error message (or 'none'):"

# --- edit above ---------------------------------------------------------
