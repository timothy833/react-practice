# 全域設定（所有 Claude Code session 皆適用）

## Repo 路徑

| 名稱 | 路徑 |
|--|--|
| 後端 | `/Users/liaoqianshun/Desktop/timothymusic-server` |
| 前端 | `/Users/liaoqianshun/Desktop/timothymusic-web` |
| 規格文件 | `/Users/liaoqianshun/Desktop/架站計畫` |

進入任何一個 repo 後，該目錄的 `CLAUDE.md` 會疊加載入，覆蓋更細的專案規則。

---

## 可用的 / 指令（Claude Code Skill）

| 指令 | 用途 |
|--|--|
| `/codex-run` | **統一多 Repo Codex 啟動**（web/server/docs 皆用這個；寫 ~/Desktop/codex_prompt.md 第一行 TARGET: web|server|docs → osascript ob-視窗 → 90s 輪詢 ~/Desktop/codex_done.flag → review → MD 同步）|
| `/ecpay-pay` | ECPay 信用卡金流串接指引 |
| `/ecpay-debug` | ECPay CheckMacValue 驗簽 debug |
| `/ecpay-go-live` | ECPay 上線前清單 |

**對應 Codex `$` 選單**（Codex 終端機自主觸發，不需要 Claude 在線）：

| `$` Skill | 用途 |
|--|--|
| `ob-runner` | 統一任務執行器（讀 ~/Desktop/codex_prompt.md 的 TARGET，自動路由到對應 repo；落回 17_進度追蹤.md [Codex] 待辦）|
| `ecpay-official-wrapper` | ECPay 金流指引 |

---

## ⚠️ Git Commit / Push 預設關閉（2026-05-28）

**預設行為：Claude 不自動 commit，不自動 push。**

| 動作 | 預設 | 開啟條件 |
|------|------|---------|
| `git commit` | ❌ 關閉 | 用戶說「幫我 commit」或「開啟 auto-commit」 |
| `git push` | ❌ 關閉 | 用戶說「push」或「開啟 auto-push」 |

**開啟方式（僅限本 session 有效）**：
- 用戶說「開啟 auto-commit」→ 本 session 可自動 commit（仍需貼 commit 草稿確認）
- 用戶說「開啟 auto-push」→ 本 session 可在用戶確認 commit 後自動 push

**適用情境**：睡前長任務批次執行時用戶主動開啟，不得 Claude 自行判斷開啟。

### ⚠️ 長流程開始前先確認 auto-push（2026-06-01 新增）

用戶說「跑到底」「一口氣跑完」「不用問我」等關鍵詞時，**第一步先詢問是否開啟 auto-push**。未確認就開跑，最後 push 卡住讓人沮喪。

### ⚠️ git 跨 repo 操作用 `git -C`（2026-06-01 新增）

操作非當前目錄的 repo 時，**一律用 `git -C /absolute/path` 而非 `cd /path && git`**。

```bash
# ✅ 正確
git -C ~/Desktop/timothymusic-web add .
git -C ~/Desktop/timothymusic-web commit -m "..."

# ❌ 錯誤：觸發「untrusted hooks」安全警告，用戶必須手動確認
cd ~/Desktop/timothymusic-web && git commit -m "..."
```

適用三個 repo：`~/Desktop/timothymusic-web`、`~/Desktop/timothymusic-server`、`~/Desktop/架站計畫`。

### ⚠️ 複雜多步驟任務用 TaskCreate 追蹤（2026-06-01 新增）

**harness 流程（多個 Codex 輪次 + review + commit）或超過 3 步驟的任務，開始前必須建 TaskCreate 清單。**

用戶需要看到「3 tasks (1 done, 1 in progress, 1 open)」這種結構才能掌握進度。沒有 TaskCreate 的長流程讓用戶看不到整體狀態。

### ⚠️ Commit 前必做：檔案數量核對（2026-05-29 新增）

review 通過、準備 commit 前，**必須先跑 `git status`**，對照 `codex_output.md` 的檔案清單：

1. `git status` 顯示的 modified/untracked 數量 = `codex_output.md` 列出的檔案數
2. 確認無誤後才 `git add` + `git commit`
3. **不得在上一輪 Codex 的變更未 commit 前，直接啟動下一輪 Codex**

原因：若兩輪 Codex 的變更混在 working tree，commit 時容易漏掉前一輪的檔案。

---

## ⚠️ 預設執行分工（所有 session 強制遵守，2026-05-25）

### Codex 啟動方式（2026-05-26 統一到桌面）

**統一用 `~/Desktop/run_once.sh`**，不再分三個 repo 各自的 run_once.sh：

| 項目 | 路徑 |
|--|--|
| 統一啟動腳本 | `~/Desktop/run_once.sh` |
| 任務來源 | `~/Desktop/codex_prompt.md`（第一行 `TARGET: web|server|docs`）|
| 完成旗標 | `~/Desktop/codex_done.flag` |
| 輸出 | `~/Desktop/codex_output.md` |
| 全域 Codex 規則 | `~/Desktop/AGENTS.md` |

**標準啟動方式（Claude 每次都用這個，不例外）：**

```bash
# 預設啟動（自動關視窗，2026-05-29 起改為預設）
# 注意：必須用 env 而不是 export，否則 osascript do script 可能接收到殘留字元導致命令錯誤
# 注意：結尾加 "; exit" 讓 zsh 在 run_once.sh 完成後自動退出，Terminal 偵測到 shell 退出才關窗
#       若只跑 run_once.sh 不加 "; exit"，子進程結束後 zsh 仍在，視窗不關
osascript << 'EOF'
tell application "Terminal"
  activate
  do script "env AUTO_CLOSE_WINDOW=true bash ~/Desktop/run_once.sh; exit"
end tell
EOF

# 保留視窗版本（用戶要求 debug / 觀察輸出時才用）
osascript << 'EOF'
tell application "Terminal"
  activate
  do script "bash ~/Desktop/run_once.sh"
end tell
EOF
```

視窗開啟後會在 Terminal 顯示 `[ob-web]` / `[ob-server]` / `[ob-docs]` 標籤，方便識別。

### 標準執行流程（每輪任務必須完整跑完）

```
① Claude  規劃 → 寫 ~/Desktop/codex_prompt.md
           第一行：TARGET: web|server|docs
           其餘：詳細任務（含 ARCHITECTURE.md 更新指令）
② Claude  rm ~/Desktop/codex_done.flag → osascript 開視窗跑 ~/Desktop/run_once.sh
           → ScheduleWakeup 90s 輪詢 ~/Desktop/codex_done.flag
③ run_once.sh  根據 TARGET 啟動 Codex（-C <repo>）
           → Codex 寫 code → 結束後自動跑 pytest/tsc/build
           → append output → touch ~/Desktop/codex_done.flag
④ Claude  flag 出現 → 讀 ~/Desktop/codex_output.md → code review
⑤ Claude  review 通過 → 整理 docs 任務
           → 寫 ~/Desktop/codex_prompt.md（TARGET: docs + docs 任務）
           → 再次執行步驟 ② ~ ④（docs 方向）
⑥ Codex   更新架站計畫 MD → touch ~/Desktop/codex_done.flag
⑦ Claude  docs review → 貼三個 repo commit 草稿給用戶
⑧ 用戶    確認 → commit → 確認 → push
```

| 步驟 | 執行者 | 內容 |
|--|--|--|
| 規劃 + 寫 `~/Desktop/codex_prompt.md` | Claude | 第一行 TARGET，其餘任務 spec |
| 寫 code + 跑測試 + 更新 ARCHITECTURE.md | Codex | via `/codex-run` |
| 寫 `~/Desktop/codex_output.md` + touch flag | Codex | 任務摘要 + 需更新 MD 清單 |
| 獨立跑 pytest/tsc/build + **Playwright**（前端改動必跑）+ code review | Claude | flag 出現後才做，不提前讀源碼 |
| 觸發 docs 同步（review 通過後必做） | Claude | 寫 docs prompt → `/codex-run` |
| 更新架站計畫 MD | Codex | via `/codex-run`（TARGET: docs）|
| Docs review + commit 草稿 | Claude | 貼給用戶確認 |
| 確認 commit + push | 用戶 | 三個 repo 一起 |

**⚠️ Playwright 強制執行原則（2026-05-29）**：
- 前端（TARGET: web）Codex 任務完成後，code review 必須包含跑 Playwright
- 指令：`PLAYWRIGHT_EXTERNAL_SERVER=1 npx playwright test tests/e2e/ --reporter=line`（需 localhost:3000 已起）
- 只跑 tsc/build 而不跑 Playwright → **不算完成**
- 只改 CSS / 純文件 / 後端 .py → 可免跑
- 回報格式必須包含：`Playwright：X passed（spec: xxx）` 或 `Playwright：本次可跳過，原因：...`

**⚠️ fetch() 直接呼叫必查 URL（2026-05-31 新增）**：

凡元件內直接呼叫 `fetch()` 而非透過 `@/lib/api` 封裝（主要用於 blob 下載、二進位回應），code review 必須確認第一個參數帶完整 base URL：

```typescript
// ❌ 錯誤：相對路徑 → 打到 localhost:3000（Next.js），沒有 proxy 則 404
const res = await fetch('/api/admin/export/combined', { ... })

// ✅ 正確：完整路徑 → 打到後端 localhost:8000
const BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'
const res = await fetch(`${BASE}/api/admin/export/combined`, { ... })
```

觸發條件：任何 `fetch('/api/` 開頭的相對路徑都是 red flag，必須改用 `${NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'}/api/...`。

**⚠️ page.route() 攔截 ≠ URL 正確驗證（2026-05-31 新增）**：

Playwright 的 `page.route('**/api/...')` glob 會同時攔截 `localhost:3000/api/...` 和 `localhost:8000/api/...`，因此測試通過**不代表 fetch URL 正確**。

- `page.route()` 攔截的測試：只能驗 UI 行為（loading state / alert 出現）
- 驗 API 串接正確性：需要讓請求**真實打出去**，用後端 response 或 `waitForResponse` 驗 status code
- 凡用了 `page.route()` 攔截某 API 的 test，必須在 code review checklist 備註「URL 正確性未在此測試中驗證」

**⚠️ ARCHITECTURE.md 行內描述核對（阻斷閘，2026-05-30 新增）**：

每個有改動的元件 / router / service 對應的 `ARCHITECTURE.md` 那一行，`←` 後的說明**必須反映最新行為**。有過期描述要當下直接 Edit 修正，不得留到下一輪。

觸發條件：元件資料來源 mock → API / prop 新增或移除 / API 路徑改動 / 新增功能說明

**⚠️ 架站計畫 MD 同步核對（commit 前阻斷閘，2026-05-30 新增）**：

code review 通過、準備 commit 前，**必須逐行核對以下清單**，不得跳過：

| 本次有改動的代碼類型 | 必須已更新的 MD |
|---|---|
| 新增/修改 `routers/*.py` | `後端模組解析/routers/XXX.md` + `00_路由解析總表.md` |
| 新增/修改 `services/*.py` | `後端模組解析/services/XXX.md` |
| 新增/修改 `schemas/*.py` | `後端模組解析/schemas/XXX.md` |
| 新增/修改 `repositories/*.py` | `後端模組解析/repositories/XXX.md` |
| 新增/修改 `models/*.py` | `資料庫/欄位說明/XXX.md` + ER 心智圖 |
| 新增/修改前端 `.tsx` 元件 | `元件解析/feature|shared/XXX.md` |
| 新增/修改前端 `page.tsx` | `頁面解析/XXX.md` |
| API 契約有改動 | 兩端 ARCHITECTURE.md + router MD + 元件 MD |
| 新增 Playwright spec | `18_測試策略.md` 覆蓋矩陣狀態更新 |

**核對流程（每次 commit 前必做）**：
1. 列出本次所有改動的檔案
2. 對照上表，找出每個改動對應的必更新 MD
3. 逐一確認對應 MD 已讀取並更新（不得只確認「檔案存在」，要確認**內容正確**）
4. 若有未更新 → **不得 commit**，先用 Agent 或直接補寫，補完後才 commit

**使用 Agent 執行 Codex 流量用完時的 MD 更新**：
- Codex 流量用完時，改用 `Agent(subagent_type="general-purpose")` **序列**處理 MD 更新（**禁止並行**，防止母 context 累積超過 1M token）
- 一次跑一個 agent，等完成後再跑下一個
- Agent prompt 必須包含：先讀程式碼 → 再讀現有 MD → 比對差異 → Write/Edit 寫入

**若有特殊原因需要 Claude 直接動手（如極小的緊急安全修補），必須先說明原因並得到用戶確認，不得自行判斷例外後直接執行。**

---

### ⚠️ codex_prompt.md 寫入規則（2026-06-01）

**必須用 `Write` 工具寫 `codex_prompt.md`，嚴禁 bash heredoc。**

原因：bash heredoc 內容若含 `{ }` 字元（TypeScript 程式碼常見），會觸發 Claude Code 的 "expansion obfuscation" 安全警告，需要用戶手動確認，破壞自動化流程。

Write 工具寫檔不觸發任何警告，是正確做法。

---

### ⚠️ Code Review + 測試派子 agent（2026-06-01）

**Codex flag 出現後，code review + 測試改派子 agent 執行，主 Claude 只看結果做 go/no-go 決定。**

原因：直接在主 context 讀大量程式碼 + 測試輸出，容易超過 1M token 上限。

子 agent 執行規則：
- `subagent_type: "general-purpose"`（或 Explore）
- prompt 包含：讀哪些檔案 + 測試指令 + 回報格式
- 主 Claude 看回傳結果決定是否 pass
- Playwright 第二跑預設在 sub-agent 中執行（`PLAYWRIGHT_EXTERNAL_SERVER=1 npx playwright test tests/e2e/ --reporter=line`）
- `codex_prompt.md` 含 `SKIP_REVIEW_PLAYWRIGHT: true` → sub-agent 跳過第二跑，只看 run_once.sh 第一跑結果

**適用情境**：每次 Codex flag 後的 code review 步驟，不只限於 Codex 流量用完時。

---

### ⚠️ 精確測試指令（2026-06-01）

**後端（docker 環境）**：
```bash
docker exec timothymusic-server-server-1 python -m pytest tests/ -q
```

**前端（三步驟，全部通過才算 pass）**：
```bash
# 1. 型別檢查
cd ~/Desktop/timothymusic-web && npx tsc --noEmit

# 2. 建構驗證
npx next build

# 3. E2E（需後端 Docker 在線）
PLAYWRIGHT_EXTERNAL_SERVER=1 npx playwright test tests/e2e/ --reporter=line
```

注意：Playwright 測試需要 `docker-compose up server` 後端在線，因為 E2E 直接打 `localhost:8000`。

---

### ⚠️ Code Review 測試覆蓋核對（阻斷閘，2026-06-01）

**每次 code review 必須核對測試覆蓋，有缺漏不得 pass。**

| 核對項目 | Server（pytest）| Web（Playwright）|
|---|---|---|
| 新增 endpoint / 元件 | `codex_output.md` 有「新補測試：tests/xxx.py」| `codex_output.md` 有「新補 spec：tests/e2e/xxx.spec.ts」|
| 行為 / schema 變動 | 確認現有 test assert 已反映新行為 | 確認現有 spec waitForResponse/locator 已反映新行為 |
| 純重構 | 全套 pytest pass | 全套 Playwright pass |
| 可跳過測試 | 純 migration/文件/env 變更 | 純 CSS/layout 無邏輯改動 |

缺漏時：要求補齊測試再重新 review，不允許帶缺漏 pass。

---

## ⚠️ Codex 流量用完 → Claude sub-agent 代替 code 任務（2026-05-30）

**觸發條件**：Codex API 流量耗盡，無法啟動新 Codex 任務。Claude 繼續主導，code 執行改用 sub-agent。

> 與「Codex 全線備用」的差異：全線備用 = Claude context 快滿，Codex 接手；流量用完 = Claude 主導不變，只有 code 執行換人。

### Sub-agent 執行規則（違反任一條不得提 commit）

**① 序列執行，禁止並行**
每次只跑一個 sub-agent。兩個 agent 同時跑會讓母 context 累積結果，容易超過 1M token 上限。

**② Sub-agent prompt 必須同時包含 code 任務 + docs 任務**
只寫 code 任務會讓 docs 漏掉。格式：

```
【程式碼任務】
（具體 spec，含檔案路徑）

【完成 code 後必須建立/更新的 MD】
- 新建：架站計畫/03_後端/後端模組解析/routers/analytics.md（從 app/routers/analytics.py 讀，列端點與說明）
- 新建：架站計畫/03_後端/資料庫/欄位說明/page_view_events.md（從 migration + model 讀欄位）
- 更新：架站計畫/03_後端/資料庫/00_資料庫入口.md（加 page_view_events 到清單 + mermaid，表數加 1）
- 更新：架站計畫/02_前端/元件解析/feature/admin/AdminDashboard.md（移除 hardcode 說明）
```

**③ Sub-agent scope 要小**
一個 sub-agent 最多一個 feature 的 code + 對應 docs。跨 feature 拆成多個 agent 序列跑。

### Claude review 阻斷閘（sub-agent 完成後，commit 前強制執行）

1. 對照本次改動類型，列出必更新 MD 清單（使用「架站計畫 MD 同步核對」表格）
2. 用 `Read` 工具逐一讀取每個 MD，確認**內容正確**（不是只 `ls` 確認存在）
3. DB model / migration 有異動時，確認 `00_資料庫入口.md` 的 mermaid + 清單 + ORM 連結三處都更新
4. 全部確認通過前，**不得提出 commit 草稿**

---

## ⚠️ Codex 全線備用（Claude context 快滿或 API 用量限制時）

**觸發條件**：Claude context 接近上限，或 Claude API 用量限制，本輪任務無法繼續主導。

**觸發後動作**：
1. Claude 在退出前把剩餘任務補寫到 `~/Desktop/架站計畫/01_前期規劃與設定/時程/17_進度追蹤.md`：
   - `### Session N 進行中`：寫到哪個步驟
   - `### Codex 可自主執行的待辦`：標 `[Codex]`，附足夠 spec 讓 Codex 不問就能開始
2. Codex 接手整條線：讀 `17_進度追蹤.md` → 找 `[Codex]` 待辦 → 執行 code + 測試 + 更新 ARCHITECTURE.md + 更新架站計畫 MD
3. Codex 完成後 touch flag + 寫 `codex_output.md`，等 Claude 回來做最終 review + commit 確認

**⚠️ Codex 全線備用時仍然要等 Claude review 通過後才能 commit，不得自行 commit。**

---

## ⚠️ 文章狀態機與存取控制（第一守則，2026-05-29 確立）

> 任何與此矛盾的舊規則、舊程式碼、舊文件，以此為準。

### 什麼是狀態機（State Machine）

**狀態機**（有限狀態機，FSM）是一種設計模式：一個實體在任一時刻只能處於一種**明確的狀態**，且只有通過**定義好的轉換條件**才能切換狀態。

**核心概念三要素：**
- **狀態（State）**：實體目前的樣態，例如文章的 `draft`、`public`、`hidden`
- **事件 / 觸發條件（Event/Guard）**：觸發狀態切換的行為，例如「點發布」「到達排程時間」「手動下架」
- **轉換（Transition）**：從一個狀態到另一個狀態的路徑，例如 `draft → public`

**為什麼用狀態機：**
不用狀態機時，程式碼到處散落 `if isPaid && !isHidden && publishedAt < now` 的判斷，容易遺漏邊界條件。用狀態機後，所有「這個資料現在是什麼狀態、允許做什麼操作」的邏輯集中在一個地方定義。

**本專案中的分工：**
- **後端**是狀態機的**守門員**：所有狀態轉換（發布、下架、排程）只在後端執行，前端不得直接改 DB 狀態
- **前端**是狀態機的**消費者**：讀取後端回傳的 `status` / `can_access` 欄位，依狀態渲染對應 UI
- 前端沒有「狀態轉換邏輯」（不自行判斷「現在是不是 public」），只有「依狀態渲染」

**文章狀態轉換圖（本專案）：**
```
             [ 新增 ]
                ↓
            draft ──→ public（發布）
              ↓  └──→ paid（付費發布）
              ↓  └──→ scheduled（排程）
              ↓              ↓ 到期自動轉
              ↓         public / paid
              ↓
           ( 從任何已發布狀態 )
                ↓ 手動下架
             hidden
```

**前端在狀態機中的角色：**

| 後端狀態 / 欄位 | 前端對應行為 |
|---|---|
| `status = 'draft'` | 只在後台管理顯示「草稿」badge，前台不顯示 |
| `status = 'public'` | 前台正常渲染文章 |
| `status = 'paid'` + `can_access: false` | 渲染 `<AuthenticatedPaywall>`，顯示付費鎖定畫面 |
| `status = 'paid'` + `can_access: true` | 正常渲染完整文章 |
| `status = 'scheduled'` | 前台不存在（後端回 404），後台顯示「排程」badge |
| `status = 'hidden'` | 前台不存在（後端回 404），後台顯示「已下架」badge |

### 文章 status 定義

| status | publishedAt | 前台可見 | 說明 |
|--------|-------------|---------|------|
| `draft` | null | ❌ | 草稿，從未發布（後端 default）|
| `public` | 過去時間（必填）| ✅ | 已發布，免費閱讀 |
| `paid` | 過去時間（必填）| ✅ | 已發布，付費閱讀 |
| `scheduled` | 未來時間（必填）| ❌ | 排程發布 |
| `hidden` | null 或有值 | ❌ | 手動下架 |

- 儲存草稿用 `status='draft'`，**不用 `hidden`**
- 前台 API 過濾：`status IN ('public','paid') AND published_at <= now AND deleted_at IS NULL`

### ✅ 已實作的存取控制（2026-05-29）

**付費文章（`GET /posts/{slug}`）**：
- 非訂閱者：200 + metadata + `can_access: false` + `content: null`（非 403）
- 訂閱者 / admin：200 + 完整內容 + `can_access: true`
- 前端 page.tsx：`!post.can_access` → `<AuthenticatedPaywall articleMeta={...} />`
- AuthenticatedPaywall：`canAccess=true` → client 重新 fetch；`canAccess=false` → metadata + PaidContentGate

**書籤 API（`GET /users/me/bookmarks`）**：
- 只回傳 `status IN ('public','paid')` 的書籤
- 另回 `hidden_count: number`（被過濾掉的書籤數）
- 前端顯示「另有 N 篇書籤文章已無法閱讀」

**Route Guard（未登入導向）**：
- `/member`、`/bookmarks`：未登入 → `ROUTES.HOME`（非 `/auth/login`）
- `/admin/**`：未登入或非 admin → `ROUTES.HOME`
- 所有 guard 等 `isSessionReady=true` 後才判斷，搭配 `return null` 防 flash

---

## 測試 / 串接 / 觀測共同規則（2026-05-25）

- auth / 會員 / 權限主線驗證固定分三層：
  1. 純前端 UI 測試（只限 tab / modal / 展開收合 / 輸入檢核 / 純文案，可不碰 API）
  2. 前後端真實串接測試（只要牽涉 submit、資料載入、登入狀態、角色、會員狀態、受保護頁，前端直接打 `http://localhost:8000`）
  3. 外部依賴驗證（Google OAuth / Email token / console / 回跳）
- 另補一層 page-load smoke test：
  - 固定重用使用者本機 `http://localhost:3000`
  - 至少檢查首頁 / 登入頁 / 文章頁
  - hydration mismatch、runtime error、非預期 `/auth/refresh 401` 一律視為失敗
- 前端本地正式後端預設是 `http://localhost:8000`
- 若 Docker `server` 容器已佔用 `8000`，前端打到的就是容器後端
- Docker backend 與本機 `uvicorn` backend 不可未記錄混用
- 前端 `access token` 只放 memory；`refresh token` 放 httpOnly cookie；不得把 auth token 放進 localStorage
- 前端啟動正式改走 `POST /api/v1/auth/session` 做 session bootstrap，不再依賴 `user_id / user_role / user_status / membership_active` 摘要 cookie
- 後續權限 / 會員方案驗證，優先使用後端建立的測試帳號，不再依賴假角色切換面板
- 後端 API 錯誤最低觀測入口：
  - `docker-compose logs -f server`（`Session 14f Phase 1` 起已可看到 request / 4xx / 5xx / traceback）
  - Swagger `/docs`
  - pytest 輸出
- `17_進度追蹤.md` 後續要同步記測試層級、通過 / 失敗數與 bug 類型

## mock 頁面改接真 API 的缺口判斷（2026-05-25）

- 當前端頁面仍有 mock / 假資料、準備改接真 API 時，先分辨缺口是哪一類，不可直接預設先補 migration：
  1. **缺 API 契約**
     - DB 其實已有資料
     - 只是 schema / service / router 尚未把資料回給前端
     - 先補 API
  2. **缺欄位**
     - 主流程所需資訊目前沒有欄位
     - 例如角色差異、可見性、排序依據、輪播內容、付款狀態
     - 這類才先補 migration
  3. **缺完整資料模型**
     - 前端整塊功能只靠假資料撐畫面
     - 後端也沒有正式 table / relation / seed 策略
     - 先做建模決策，再開始補 API
- 排 task 或委派 Codex 前，至少要寫清楚：
  - 是缺 API、缺欄位，還是缺模型
  - 是否阻塞真流程
  - 是否值得先補 migration

---

## ⚠️ 17_進度追蹤.md 更新時機（必須遵守）

**唯一入口**：`~/Desktop/架站計畫/01_前期規劃與設定/時程/17_進度追蹤.md`

### 更新時機（兩種，都必須做）

**① 每輪 harness 完成後立即更新**（不等 session 結束）

每次 Codex → review → commit → push 一輪跑完，**立即**在 `17_進度追蹤.md` 補當日記錄：
- 格式：commit hash + 具體做了什麼 + 結果
- 不需用戶提醒，這是 harness 流程的最後一步

**② Session 結束前補齊**

用戶說「好了」「先這樣」「下次再繼續」等，或 context 快滿前：
1. 確認今日所有完成項都已寫入 `## 最近工作記錄`
2. 若有未完成任務，補入 `## ⚠️ 待完成項目` 或 `### Codex 可自主執行的待辦`（標 `[Codex]`，附足夠 spec）
3. 若有新 bug 或阻塞，補入對應 warning 段落

**目的**：用戶隨時可看到今日做了什麼、還有什麼待辦，不依賴記憶或對話歷史。所有 agent 換 session 時只需讀這一個檔案即可掌握全局。

---

## ⚠️ Codex Code Review 完成後自動同步文件（必須遵守）

任何 `/codex-run`（TARGET: web 或 server）的 code review 通過後，Claude **必須自動接著做 MD 同步**，不得等用戶提醒。

### 觸發條件

Codex code review 通過（build pass + tsc pass + 規則對照 OK）。

### 自動執行步驟

1. **整理 doc 任務**：從 `~/Desktop/codex_output.md` 的「需更新 MD」清單，加上 review 過程中實際看到的元件/API 變更，列出需要新建或更新的架站計畫 MD
2. **寫入 `~/Desktop/codex_prompt.md`**（TARGET: docs + docs 任務描述）：列清楚每個 MD 要改什麼
3. **再次執行 `/codex-run`（docs 方向）**：rm `~/Desktop/codex_done.flag` → osascript 開視窗跑 `~/Desktop/run_once.sh` → ScheduleWakeup 90s 輪詢 `~/Desktop/codex_done.flag`

### 什麼情況可以跳過

- 本次 Codex 任務純粹是 bug fix，沒有新增元件、沒有改 API 合約、沒有新頁面
- 已存在的元件 MD 內容完全不需要更新（如只改了 CSS）
- 跳過時需在回報中明確說明「本次不需要 MD 同步，原因：...」

### ⚠️ 以下情況不得跳過（即使沒有新元件或路由）

- `src/data/*.ts` 的 `export type` 有改動 → grep 架站計畫 `02_前端文件與設定/元件解析/` 找舊值，有則必須啟動 /codex-run（TARGET: docs）
- 修改了現有元件且 `架站計畫/02_前端文件與設定/元件解析/` 有對應 MD → 確認 MD 描述是否過期
- 任何 status / enum 值改名或新增 → 搜尋架站計畫相關 MD 是否有引用舊值，有則補任務

---

## ⚠️ 文件強制同步規則（代碼與文件必須同步，Claude 與 Codex 皆適用）

**代碼改動後，對應的所有文件必須在同一批任務內更新完畢，不得拖到下一輪。**

### 完整觸發清單

| 代碼變動類型 | 必須更新的文件 |
|---|---|
| 新增 / 修改前端元件（`.tsx`）| 前端 `ARCHITECTURE.md` + `架站計畫/02_前端/元件解析/XXX.md` |
| 新增 / 修改前端頁面（`page.tsx`）| 前端 `ARCHITECTURE.md` + `架站計畫/02_前端/頁面解析/XXX.md` |
| 新增 / 修改前端入口 / layout / store | 前端 `ARCHITECTURE.md`（路由表 / 狀態管理段落）|
| 新增 / 修改後端 router（`routers/*.py`）| 後端 `ARCHITECTURE.md` + `架站計畫/03_後端/後端模組解析/routers/XXX.md` |
| 新增 / 修改後端 service（`services/*.py`）| `架站計畫/03_後端/後端模組解析/services/XXX.md` |
| 新增 / 修改後端 schema（`schemas/*.py`）| `架站計畫/03_後端/後端模組解析/schemas/XXX.md` |
| 新增 / 修改後端 repository（`repositories/*.py`）| `架站計畫/03_後端/後端模組解析/repositories/XXX.md` |
| 新增 / 修改 DB model（`models/*.py`）| `架站計畫/03_後端/資料庫/欄位說明/XXX.md` + **ER 心智圖**（`架站計畫/03_後端/資料庫/ER_diagram.md`）|
| 新增 Alembic migration | 同上（欄位說明 + ER 心智圖）|
| 前後端 API 契約有改動（新端點 / 改 request-response schema）| 兩端 ARCHITECTURE.md + 對應 router MD + 對應前端元件 MD |
| 修改全域設定（`next.config.ts` / `main.py` / docker-compose）| 對應 repo 的 `ARCHITECTURE.md` 入口 / 架構段落 |

### ER 心智圖 / 資料表更新規則（DB 異動時強制）

- 新增資料表或欄位 → 更新 `架站計畫/03_後端/資料庫/` 下的 ER mermaid，加入新 entity / 欄位
- 建立新關聯（FK / relationship）→ 同步更新 ER 關聯線
- 欄位改名 / 刪除 → 確認 ER 圖有無舊名，有則同步修正
- **禁止只更新欄位說明 MD 而不更新 ER 圖**（兩者必須一致）

### 文件更新原則：程式碼優先（Code First, Docs Second）

**MD 更新的唯一依據是「實際程式碼」，不得以「舊 MD」作為依據更新 MD。**

| 更新情境 | Claude 必須先做 |
|---|---|
| 後端模組解析 MD（routers / services / schemas / models）| Read 讀取對應 `.py` 完整檔案 |
| 前端元件 / 頁面解析 MD | Read 讀取對應 `.tsx` / `.ts` 完整檔案 |
| 資料庫欄位 MD / Schema 說明 | Read 讀取 `app/models/*.py`；Docker 有跑時用 `docker exec ... psql \d+ tablename` 直接查 |
| migration 紀錄 | `ls migrations/versions/` 取完整清單，逐一核對未記錄的 revision |
| ARCHITECTURE.md | `ls` 實際目錄結構 + Read 相關程式碼，不依賴記憶或舊 MD |

**絕對禁止**：
- 讀舊 MD 內容 → 直接改寫新 MD（文檔到文檔，必定失真）
- 僅用 `ls` 比對清單，未讀程式碼就更新欄位說明
- 根據記憶推斷 MD 內容而未實際看過程式碼
- 只更新部分文件（觸發清單中列出的文件必須全部更新）

---

## ⚠️ Claude 文件核對機制（2026-05-29 新增，強制）

**過去問題**：Code review 只確認 MD「是否存在」，沒有讀 MD 內容確認正確性，導致文件與程式碼脫節累積。

### Codex code review 通過後，Claude 必須執行的文件核對流程

在啟動 docs Codex 任務之前，Claude 必須自己先做以下核對（用 Read 工具或 grep 實際讀取 MD 內容）：

#### 後端變更核對清單

| 變更類型 | Claude 必須讀的 MD | 核對重點 |
|---|---|---|
| 新增或修改 `routers/X.py` | `後端模組解析/routers/X.md` | MD 列出的端點是否涵蓋所有 `@router.get/post/patch/delete`；有無缺漏方法或路徑 |
| 修改 `core/exceptions.py` | `後端模組解析/core/exceptions.md` | 錯誤格式描述是否與實際 handler 一致（422/500 是否描述為統一 `{ success, error }` 格式）|
| 修改 `schemas/X.py` | `後端模組解析/schemas/X.md` | MD 列的欄位是否與實際 Pydantic model 一致 |
| 修改 `services/X_service.py` | `後端模組解析/services/X_service.md` | MD 描述的函式是否仍存在於實際 .py |
| 新增 router / service / schema 但無對應 MD | — | 直接在 docs Codex spec 裡寫「新建 XXX.md，內容：...」|

#### 前端變更核對清單

| 變更類型 | Claude 必須讀的 MD | 核對重點 |
|---|---|---|
| 修改元件的錯誤處理 | `元件解析/feature|shared/XXX.md` | MD 是否還描述舊的 hardcode 猜格式邏輯（`error.response?.data?.detail`）|
| 路徑改為 `ROUTES.*` | 同上 | MD 是否還有 hardcode 路徑字串（如 `/auth/login`、`/admin`）|
| 資料來源從 mock 改為 API | 同上 | MD 的「資料取得方式」或「資料來源」段落是否已更新 |
| API 路徑有改動（如移除 /v1）| 同上 | MD 裡是否還有舊的 API 路徑 |
| 新增元件（無對應 MD）| — | 直接在 docs Codex spec 裡寫「新建 XXX.md，主要行為：...」|
| 頁面新增 prop 或移除 prop | `頁面解析/pages/XXX.md` | MD 的元件組成是否同步 |

#### 核對結果寫入 docs Codex spec

找到過期內容後，在 `codex_prompt.md`（TARGET: docs）裡具體說明每個 MD 要改哪個段落：

```
# 任務：文件同步
T1：更新 元件解析/feature/auth/LoginForm.md
  - 第 3 節「錯誤處理」：移除舊的 detail 猜格式邏輯，改為 parseApiError 說明
T2：新建 元件解析/feature/blog/AuthenticatedPaywall.md
  - 主要行為：canAccess guard + 付費文章完整內容載入
```

**不可只寫「更新 XXX.md」而不說明改哪裡** — 這樣 Codex 無法執行準確的更新。

### 回報格式補充

```
Codex 完成 + Review 通過 ✅
- ...（程式碼 review 項目）
build：pass / tsc：pass

→ 自動啟動 /codex-run（TARGET: docs）同步以下 MD：
  - 更新：xxx.md
  - 新建：yyy.md
```
