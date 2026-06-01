#!/bin/bash
# 統一多 Repo 啟動腳本（桌面主控 ob-runner）
#
# 使用方式：
#   1. 寫好 ~/Desktop/codex_prompt.md，第一行寫 TARGET: web|server|docs
#   2. 直接跑此腳本（或由 Claude 的 osascript 呼叫）
#
# 輸出統一到：
#   ~/Desktop/codex_output.md
#   ~/Desktop/codex_done.flag

DESKTOP="$HOME/Desktop"
DONE="$DESKTOP/codex_done.flag"
OUTPUT="$DESKTOP/codex_output.md"
PROMPT_FILE="$DESKTOP/codex_prompt.md"

# 任務完成後是否自動關閉此 Terminal 視窗（預設 false）
# 開啟方式：執行前 export AUTO_CLOSE_WINDOW=true，或直接改此行
AUTO_CLOSE_WINDOW=${AUTO_CLOSE_WINDOW:-false}

echo "🚀 [ob-runner] 啟動... $(date '+%H:%M:%S')"
echo ""

# 清除舊 flag（output 由 Codex 自己寫，不強制清空）
rm -f "$DONE"

# 讀取 prompt
PROMPT=$(cat "$PROMPT_FILE" 2>/dev/null)
if [ -z "$PROMPT" ]; then
  echo "⚠️  ~/Desktop/codex_prompt.md 為空，中止"
  exit 1
fi

# 解析 TARGET（第一行 "TARGET: web|server|docs"）
TARGET=$(head -3 "$PROMPT_FILE" | grep -oE "TARGET:\s*(web|server|docs)" | sed 's/TARGET:[[:space:]]*//' | head -1)
if [ -z "$TARGET" ]; then
  echo "⚠️  codex_prompt.md 缺少 TARGET: web|server|docs（前三行必須有），中止"
  exit 1
fi

case "$TARGET" in
  web)
    REPO="$DESKTOP/timothymusic-web"
    LABEL="ob-web"
    ;;
  server)
    REPO="$DESKTOP/timothymusic-server"
    LABEL="ob-server"
    ;;
  docs)
    REPO="$DESKTOP/架站計畫"
    LABEL="ob-docs"
    ;;
  *)
    echo "⚠️  TARGET 值不正確：$TARGET（只接受 web / server / docs）"
    exit 1
    ;;
esac

echo "📌 Target: $TARGET → $REPO"
echo "🖥️  Codex 啟動層：$DESKTOP（-C Desktop，可寫 output/flag）"
echo "📝 啟動 Codex ($LABEL)..."
echo ""

# Step 1：啟動 background 視窗監看器（AUTO_CLOSE_WINDOW=true 時才啟動）
# 用 pkill 直接終止 Codex process，避免舊版 do script 把指令送到 Codex stdin
# 而非 bash shell，導致 kill %1 失效的問題。
if [ "$AUTO_CLOSE_WINDOW" = "true" ]; then
  (
    while [ ! -f "$DONE" ]; do sleep 3; done
    sleep 10
    echo "🔲 flag 已出現，終止 Codex 進程..."
    pkill -TERM -f "codex" 2>/dev/null
    sleep 3
    pkill -KILL -f "codex" 2>/dev/null  # 若未響應 TERM，強制終止
  ) &
  WATCHER_PID=$!
fi

# Step 2：Codex（-a never 全自動，-s danger-full-access 允許執行任意程序含 Chrome/Playwright）
# -C 桌面層級讓 Codex 可寫 codex_output.md / codex_done.flag
# -s danger-full-access 解除 sandbox 限制，Codex 可自行跑 tsc / build / E2E
# 注意：codex 完成任務後會停在互動式 prompt 不退出，以下代碼可能不執行
codex -C "$DESKTOP" -a never -s danger-full-access "$PROMPT"
echo ""
echo "✅ $(date '+%H:%M:%S') Codex 執行完畢"

# Codex 可能依 AGENTS.md 在任務結束時自行 touch done flag，
# 在測試跑完之前先清掉，確保 Claude 不會讀到不完整的 output。
rm -f "$DONE"

# Step 2：測試（web = tsc + next build；server = docker pytest；docs = 無）
case "$TARGET" in
  web)
    echo "🧪 tsc + next build..."
    source ~/.nvm/nvm.sh
    cd "$REPO"
    TSC_OUT=$(node_modules/.bin/tsc --noEmit 2>&1); TSC_EXIT=$?
    BUILD_OUT=$(node_modules/.bin/next build 2>&1 | tail -20); BUILD_EXIT=$?

    {
      echo ""
      echo "---"
      echo "## tsc + build 結果（run_once.sh，$(date '+%H:%M:%S')）"
      echo ""
      echo "### tsc"
      echo '```'
      [ $TSC_EXIT -eq 0 ] && echo "pass（0 errors）" || echo "$TSC_OUT"
      echo '```'
      echo ""
      echo "### next build"
      echo '```'
      echo "$BUILD_OUT"
      echo '```'
      if [ $TSC_EXIT -eq 0 ] && [ $BUILD_EXIT -eq 0 ]; then
        echo ""
        echo "**結果：tsc pass ✅ / build pass ✅**"
      else
        echo ""
        echo "**結果：有錯誤 ❌，請 Claude review**"
      fi
    } >> "$OUTPUT"

    # Playwright 第一跑（需 localhost:3000 在線）
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
      echo "🎭 Playwright 第一跑..."
      PW_OUT=$(CI=1 PLAYWRIGHT_EXTERNAL_SERVER=1 node_modules/.bin/playwright test tests/e2e/ --reporter=line 2>&1)
      PW_EXIT=$?
      {
        echo ""
        echo "---"
        echo "## Playwright 第一跑（run_once.sh，$(date '+%H:%M:%S')）"
        echo ""
        echo '```'
        echo "$PW_OUT" | tail -30
        echo '```'
        [ $PW_EXIT -eq 0 ] && echo "" && echo "**結果：全部通過 ✅**" || echo "" && echo "**結果：有 failed ❌，請 Claude review**"
      } >> "$OUTPUT"
    else
      {
        echo ""
        echo "---"
        echo "## Playwright 第一跑（跳過）"
        echo "localhost:3000 未啟動，跳過 Playwright。第二跑由 Claude sub-agent 負責。"
      } >> "$OUTPUT"
      echo "⚠️  localhost:3000 未啟動，Playwright 第一跑跳過"
    fi
    ;;

  server)
    echo "🧪 docker pytest..."
    cd "$REPO"
    docker-compose up -d server 2>&1 | tail -3
    sleep 5
    PYTEST_OUT=$(docker-compose exec server python -m pytest tests/ -q 2>&1); PYTEST_EXIT=$?

    echo "$PYTEST_OUT" | tail -5
    {
      echo ""
      echo "---"
      echo "## pytest 結果（run_once.sh，$(date '+%H:%M:%S')）"
      echo ""
      echo '```'
      echo "$PYTEST_OUT" | tail -15
      echo '```'
      [ $PYTEST_EXIT -eq 0 ] && echo "" && echo "**結果：全部通過 ✅**" || echo "" && echo "**結果：有 failed ❌，請 Claude review**"
    } >> "$OUTPUT"
    ;;

  docs)
    echo "📚 docs 任務無需執行測試"
    ;;
esac

# Step 3：touch done flag（統一到桌面）
touch "$DONE"
echo ""
echo "🏁 $(date '+%H:%M:%S') 完成 → ~/Desktop/codex_done.flag 已觸發，等待 Claude review"

# 若 watcher 子進程仍在跑（codex 有正常退出的情況），清掉它
[ -n "${WATCHER_PID:-}" ] && kill "$WATCHER_PID" 2>/dev/null || true

# 自動關閉 Terminal 視窗：
# run_once.sh 本身 exit 0 只退出子進程（bash run_once.sh），Terminal 的 zsh 仍在，視窗不關。
# 真正讓視窗關閉的是啟動時在 do script 加 "; exit"，讓 zsh 在此腳本結束後接著退出。
# 本行 exit 0 確保腳本以正常碼結束，讓外層 "; exit" 能被 zsh 執行。
if [ "$AUTO_CLOSE_WINDOW" = "true" ]; then
  exit 0
fi
