# Codex 多 Repo 統一協作規則（桌面主控）

> 本檔案放在 `~/Desktop/`，對所有 Desktop 子 repo 的 Codex instance 生效。
> 取代原本散落在各 repo 的重複規則，各 repo 的 AGENTS.md 只寫 repo 專屬差異。

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
