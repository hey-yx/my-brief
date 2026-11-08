#!/bin/bash
# 等待看板卡全部完成并合入 main：monitor-completion.sh <board> <card_id...>
# 双条件：tasks.status=done 且分支是 main 祖先（merge-base --is-ancestor）。
# 休眠会杀本脚本；醒来重跑即可，无需补状态。
set -u
BOARD="${1:?usage: monitor-completion.sh <board> <card_id...>}"
shift
CARDS="$*"
[ -n "$CARDS" ] || { echo "usage: monitor-completion.sh <board> <card_id...>"; exit 64; }
DB="$HOME/.hermes/kanban/boards/$BOARD/kanban.db"
REPO="$(pwd)"
MAX_WAIT=$((3*3600))
START=$(date +%s)
while :; do
  now=$(date '+%F %T')
  all_done=1; all_merged=1; line=""
  for c in $CARDS; do
    row=$(sqlite3 "$DB" "SELECT status||'|'||COALESCE(branch_name,'') FROM tasks WHERE id='$c'" 2>/dev/null)
    st=${row%%|*}; br=${row#*|}
    [ "$st" = "done" ] || all_done=0
    if [ -n "$br" ] && git -C "$REPO" merge-base --is-ancestor "$br" main 2>/dev/null; then
      m=merged
    else
      m=unmerged; all_merged=0
    fi
    line="$line ${c}=${st:-missing}/${m}"
  done
  echo "[$now]$line"
  if [ $all_done -eq 1 ] && [ $all_merged -eq 1 ]; then
    echo "MONITOR_DONE all $(( $(echo $CARDS | wc -w) )) cards done and merged into main"
    exit 0
  fi
  if [ $(( $(date +%s) - START )) -ge $MAX_WAIT ]; then
    echo "MONITOR_TIMEOUT after 3h, last:$line"
    exit 2
  fi
  sleep 120
done
