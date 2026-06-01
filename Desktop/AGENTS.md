# Codex 多 Repo 統一協作規則（桌面主控）

> 本檔案放在 `~/Desktop/`，對所有 Desktop 子 repo 的 Codex instance 生效。
> 取代原本散落在各 repo 的重複規則，各 repo 的 AGENTS.md 只寫 repo 專屬差異。

---

## ⚠️ 第一守則：文章狀態機定義（前後端統一）

> 任何與此矛盾的舊規則、舊程式碼、舊文件，以此為準。

### 什麼是狀態機

狀態機（FSM）：一個實體在任一時刻只能有一種**明確狀態**，且只能通過**定義好的轉換條件**切換。

**本專案分工：**
- **後端**是狀態機守門員：所有狀態轉換只在後端執行，前端不自行判斷轉換
- **前端**是消費者：讀 `status` / `can_access` → 依狀態渲染 UI，不含轉換邏輯

**文章狀態轉換：**
`draft` → `public` / `paid` / `scheduled`（發布）→ `hidden`（下架）

**前端依狀態渲染對照：**
- `public` → 正常渲染
- `paid` + `can_access: false` → `<AuthenticatedPaywall>`
- `paid` + `can_access: true` → 正常渲染全文
- `draft` / `hidden` / `scheduled` → 前台不存在（後端回 404）

---

| status | publishedAt | 前台可見 | 說明 |
|--------|-------------|---------|------|
| `draft` | null | ❌ | 草稿，從未發布，仍在編輯中 |
| `public` | 過去時間（必填）| ✅ | 已發布，免費閱讀 |
| `paid` | 過去時間（必填）| ✅ | 已發布，付費閱讀 |
| `scheduled` | 未來時間（必填）| ❌（時間到前）| 排程發布，到時間後自動轉 public/paid |
| `hidden` | null 或有值 | ❌ | 手動下架 |

**核心規則**：
- 儲存草稿 → `status = 'draft'`（後端 default，**不用 `hidden`**）
- 手動下架 → `status = 'hidden'`（保留原本 publishedAt）
- 前台 API 過濾：`status IN ('public','paid') AND published_at <= now AND deleted_at IS NULL`
- `draft` / `hidden` / `scheduled` 對公開 API 均 404
- `paid` 文章對非訂閱者：✅ **已實作** 200 + metadata + `can_access: false`，`content: null`（非 403）
- Admin 後台：`draft` → 草稿 badge；`hidden` → 已下架 badge；`scheduled` → 排程 badge
- 書籤 API（`GET /users/me/bookmarks`）：✅ **已實作** 只回 `status IN ('public','paid')` 書籤 + `hidden_count`，hidden/scheduled 不回傳 metadata（零信任後端卡控）

---

## ⚠️ 任務來源優先順序（每次啟動都要做）

1. 讀 `~/Desktop/codex_prompt.md`
   - 有內容 → 直接執行，看第一行 `TARGET:` 決定工作 repo
   - 為空 → 進入步驟 2
2. 讀 `~/Desktop/架站計畫/01_前期規劃與設定/時程/17_進度追蹤.md`，找 `## Session N 規劃` 中標記 `[Codex]` 的待辦
3. 兩者都無 → 在 `~/Desktop/codex_output.md` 寫「無待辦任務，請 Claude 指派」，touch flag 後結束

---

## codex_prompt.md 格式

```
TARGET: web|server|docs

<任務描述...>
```

`TARGET` 指定工作 repo：
- `web` → `~/Desktop/timothymusic-web`
- `server` → `~/Desktop/timothymusic-server`
- `docs` → `~/Desktop/架站計畫`

---

## ⚠️ 完成後必做（全部寫到桌面，強制）

```bash
touch ~/Desktop/codex_done.flag
```

摘要寫入 `~/Desktop/codex_output.md`，包含：
- 新建 / 修改的檔案清單（含 repo 前綴，如 `timothymusic-server/app/...`）
- 測試 / build 結果
- 需更新 MD 清單（格式：`需更新 MD：架站計畫/03_後端.../xxx.md`）
- 若從 `17_進度追蹤.md` 取得任務，說明執行了哪一條
- 建議 commit log（附在末尾）

---

## 多 Repo 讀取規則

| 操作 | 規則 |
|--|--|
| 讀取其他 repo 的程式碼或文件 | 使用絕對路徑，如 `/Users/liaoqianshun/Desktop/timothymusic-server/app/...` |
| 讀取架站計畫規格 | 絕對路徑 `cat`，任何 Codex instance 都可讀 |
| 寫入程式碼 | 只寫當前 `-C` 指定的 repo |
| 寫入架站計畫 MD | 標記在 `~/Desktop/codex_output.md` 的「需更新 MD」，不直接跨 repo 寫入 |

---

## 測試與 Auth 執行基線（2026-05-26）

- 任何 submit / 資料載入 / 登入狀態 / 角色 / 會員方案 / 受保護頁 → 必須串 **真實 API**
- 只有純前端互動外殼可不串 API：tab 切換、modal 開關、展開收合、格式檢核、文案顯示
- 前後端真實串接時前端打 `http://localhost:8000`
- auth token 只放 memory；refresh token 走 httpOnly cookie；不得放 localStorage
- 前端啟動走 `POST /api/v1/auth/session`，不得再依賴摘要 cookie 做 guard

---

## ⚠️ 後端測試先行規則（TARGET: server 任務必讀，2026-06-01 新增）

**新增 API endpoint → 同任務必須補對應 pytest，不可分成另一輪。**

| 改動類型 | 必補測試 | 最低要求 |
|---|---|---|
| 新增 router endpoint | `tests/test_<module>_router.py` | happy path（200/201）+ 至少一個錯誤路徑（401/403/422）|
| 新增 service 方法 | `tests/test_<module>_service.py` | happy path + 邊界情況 |
| 修改現有 endpoint 行為 | 更新對應現有 test | 新行為必須有斷言，不只是「舊 test pass」|
| 修改 response schema | 更新 test 內的 `response.json()` 斷言 | 確認 schema 與測試一致 |
| 純重構（不改 API 行為）| 不需補新 test | 跑全套 pytest 確認無 regression |

**Codex checklist**：codex_output.md 測試結果需標注「新補測試：tests/test_xxx.py（N cases）」或說明無需補的原因。

---

## ⚠️ 前端測試執行規則（TARGET: web 任務必讀，2026-05-29 新增）

### Codex 必跑（有 browser 前無法跑 Playwright，分工如下）

| 改動類型 | Codex 執行 | Claude 執行（code review 時）|
|---|---|---|
| modal / 表單 / store / tabs 互動 | `npm run test:unit`（Vitest）| 視情況補跑 page-load-smoke |
| 新增頁面 / 路由 | 補寫對應 `.spec.ts` | 跑新增的 spec + page-load-smoke |
| 改了 auth / session / route guard | 無需 Codex 額外操作 | 跑 auth-flows + auth-account-flows |
| 改了部落格 / 文章 / 後台頁面 | 無需 Codex 額外操作 | 跑 blog-admin-flows |
| 只改 CSS / 後端 .py / 純文件 | 無需 Codex 額外操作 | 跳過 Playwright |

### Codex 任務完成前必做：

1. **若改了 modal / 表單 / store / tabs** → 跑 `npm run test:unit`，確認全 passed 才 touch flag
2. **若新增了頁面或使用者流程** → 同一任務補寫對應 `tests/e2e/*.spec.ts`，並在 `codex_output.md` 標注：
   ```
   需跑 spec（Claude code review 時執行）：tests/e2e/xxx.spec.ts
   ```
3. **若 unit test 失敗** → 修正後才能 touch flag，不得帶著 failing test 結案

### Playwright 由 Claude 負責（Codex 環境無 browser）

Codex 不執行 `npx playwright test`。Claude 在 code review 階段跑。
Codex 的責任是：補寫 spec + 在 output 說明「需跑哪個 spec」。

---

## 前後端串接缺口判斷（2026-05-25）

串接前先判斷缺口類型，不得直接預設補 migration：

1. **缺 API 契約** → 補 schema/service/router，不先動 migration
2. **缺欄位** → 補欄位 / migration
3. **缺完整資料模型** → 先做建模決策，再開始補 API

---

## ⚠️ Alembic Migration 環境限制（server 任務必讀）

timothymusic-server 的 `.env` DB host 是 Docker service name（`@db:5432`），  
**只在 Docker 容器內部可解析，Codex 在 Docker 外跑，`alembic upgrade head` 一定失敗（DNS error）。**

**Codex 應做：**
1. 建立 migration 檔（autogenerate 或手動等價）
2. **不執行 `alembic upgrade head`**
3. 在 `codex_output.md` 末尾標注：`⚠️ migration 已建立，需 Claude 在 review 後執行：docker exec timothymusic-server-server-1 alembic upgrade head`

Claude 在 review 通過後手動執行 `docker exec timothymusic-server-server-1 alembic upgrade head`。

---

## ⚠️ 文件強制同步清單（代碼變動後必做，Claude 與 Codex 皆適用）

**原則：代碼與文件必須同步。任何代碼改動後，對應文件必須在同一批任務內更新完畢，不得拖到下一輪。**

### 觸發條件 → 必須更新的文件

| 代碼變動類型 | 必須更新的文件 |
|---|---|
| 新增 / 修改前端元件（`.tsx`）| 前端 `ARCHITECTURE.md` + `架站計畫/02_前端/元件解析/XXX.md` |
| 新增 / 修改前端頁面（`page.tsx`）| 前端 `ARCHITECTURE.md` + `架站計畫/02_前端/頁面解析/XXX.md` |
| 新增 / 修改前端入口 / layout / store | 前端 `ARCHITECTURE.md`（路由表 / 狀態管理段落）|
| 新增 / 修改後端 router（`routers/*.py`）| 後端 `ARCHITECTURE.md` + `架站計畫/03_後端/後端模組解析/routers/XXX.md` |
| 新增 / 修改後端 service（`services/*.py`）| `架站計畫/03_後端/後端模組解析/services/XXX.md` |
| 新增 / 修改後端 schema（`schemas/*.py`）| `架站計畫/03_後端/後端模組解析/schemas/XXX.md` |
| 新增 / 修改後端 repository（`repositories/*.py`）| `架站計畫/03_後端/後端模組解析/repositories/XXX.md` |
| 新增 / 修改 DB model（`models/*.py`）| `架站計畫/03_後端/資料庫/欄位說明/XXX.md` + **mermaid ER 心智圖**（`架站計畫/03_後端/資料庫/ER_diagram.md` 或同路徑心智圖）|
| 新增 Alembic migration | 同上（欄位說明 + ER 心智圖）|
| 前後端 API 契約有改動（新增端點 / 改 request-response schema）| 兩端 ARCHITECTURE.md + 對應 router MD + 對應前端元件 MD |
| 修改全域設定（`next.config.ts` / `main.py` / docker-compose）| 對應 repo 的 `ARCHITECTURE.md` 入口 / 架構段落 |

### 心智圖 / ER 圖更新規則（資料表異動時強制）

- 新增資料表或欄位 → 找到 `架站計畫/03_後端/資料庫/` 下的 ER mermaid，加入新 entity / 欄位
- 建立新關聯（FK / relationship）→ 同步更新 ER 關聯線
- 欄位改名 / 刪除 → 先確認 ER 圖中有無舊名，有則同步修正
- **禁止只更新欄位說明 MD 而不更新 ER 圖**（兩者必須一致）

### 代碼優先原則

**更新任何 MD 前，必須先讀對應的實際程式碼檔案，不得以「舊 MD → 新 MD」的方式更新。**

| 更新情境 | 必讀對象（Read 工具，完整讀取）|
|---|---|
| 後端模組解析 MD（routers / services / repositories / schemas）| 對應的 `.py` 實際檔案 |
| 後端 models MD / 資料庫欄位 MD | 對應的 `app/models/*.py`；有 DB 連線時優先用 `psql \d+ tablename` |
| 前端元件解析 MD | 對應的 `.tsx` / `.ts` 實際檔案 |
| ARCHITECTURE.md（任一 repo）| 對應的實際目錄結構與程式碼，不依賴記憶 |
| 資料庫 Schema MD（欄位 / 關聯 / Index）| 實際 `app/models/*.py` + 最新 migration 檔，兩者都讀 |

**絕對禁止做法**：
- 讀舊 MD → 改寫新 MD（文檔到文檔，必定失真）
- 僅 `ls` 比對清單，未讀程式碼內容就更新欄位說明
- 根據記憶或推斷撰寫 MD，而非實際看過程式碼
- 只更新部分文件（觸發條件中列出的文件必須全部更新）

---

## ⚠️ 架站計畫 MD 同步核對（codex_output.md 必填，2026-05-30 新增）

**任務完成、寫入 `codex_output.md` 前，Codex 必須逐行核對以下清單，填入「需更新 MD」欄位：**

| 本次有改動的代碼類型 | 必須標注的 MD |
|---|---|
| 新增/修改 `routers/*.py` | `架站計畫/後端模組解析/routers/XXX.md` + `00_路由解析總表.md` |
| 新增/修改 `services/*.py` | `架站計畫/後端模組解析/services/XXX.md` |
| 新增/修改 `schemas/*.py` | `架站計畫/後端模組解析/schemas/XXX.md` |
| 新增/修改 `repositories/*.py` | `架站計畫/後端模組解析/repositories/XXX.md` |
| 新增/修改 `models/*.py` | `架站計畫/資料庫/欄位說明/XXX.md` + ER 心智圖 |
| 新增/修改前端 `.tsx` 元件 | `架站計畫/元件解析/feature|shared/XXX.md` |
| 新增/修改前端 `page.tsx` | `架站計畫/頁面解析/XXX.md` |
| API 契約有改動（新端點/改 request-response）| router MD + 元件 MD + ARCHITECTURE.md |
| 新增 Playwright spec | `架站計畫/04_QA_資安與其他/18_測試策略.md` 覆蓋矩陣 |

**格式**（在 `codex_output.md` 末尾的「需更新 MD」段落）：
```
需更新 MD：
- 架站計畫/後端模組解析/routers/tags.md（補 POST/PATCH/DELETE 三個端點）
- 架站計畫/後端模組解析/schemas/tag.md（補 TagCreate/TagUpdate/TagDeleteResponse）
- 架站計畫/00_路由解析總表.md（tag ⬜ → ✅）
```

**不得只寫「需更新 MD：無」** 除非本次確認無任何觸發條件符合（需逐行核對後才能確認）。

---

## ⚠️ git 跨 repo 操作規則（2026-06-01）

Claude 負責所有 git 操作。Codex 不執行 `git commit` / `git push`（見絕對禁止清單）。

**Claude 跨 repo git 的正確寫法（供 Claude 參考，記錄在此避免重複踩坑）**：
- 用 `git -C /absolute/path command`
- 不用 `cd /path && git command`（觸發 Claude Code 安全警告）

---

## 絕對禁止

- `git commit` / `git push`
- 跨 repo 直接寫入（改在 `~/Desktop/codex_output.md` 標注「需更新 MD」）
- 自行擴大任務範圍
- 刪除用戶現有檔案（除非 prompt 明確指示）

---

## Commit log 格式（附在 `~/Desktop/codex_output.md` 末尾）

```
feat(scope): Session Nxx 任務名稱

- 新建 Xxx（說明用途或設計決策）
- 修改 Yyy（說明原因）
- 安裝 / 移除 套件名稱（說明為何需要）

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

規則：type/scope 英文；主標題與 bullet 全部中文；不自行 commit，附給 Claude 確認後執行
