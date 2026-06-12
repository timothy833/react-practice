# 全域設定（標準化重盤版，2026-06-12）

> 工作流已重盤到標準骨架：**規格住 OpenSpec、流程住 Superpowers、通用教訓住 ops-playbooks plugin、專案細則住各 repo CLAUDE.md**。本檔只留：路徑事實、git 紀律、協作風格、進度追蹤。
> 重盤對映表：`~/Desktop/agent-ops/07_重盤對映表.md`；舊版全文備份：`~/.claude/backups/CLAUDE.md.pre-rebase-2026-06-12`。

## Repo 路徑

| 名稱 | 路徑 |
|--|--|
| 後端 | `~/Desktop/timothymusic-server` |
| 前端 | `~/Desktop/timothymusic-web` |
| 規格/現況文件 | `~/Desktop/架站計畫` |
| Agent 營運主線 | `~/Desktop/agent-ops`（架構決策 02、階段計畫 03） |

各 repo 的測試指令、文件同步閘門、技術慣例 → 該 repo 的 `CLAUDE.md`。
ECPay 金流問題 → `/ecpay-pay`、`/ecpay-debug`、`/ecpay-go-live` skills。

## 標準工作流

- **任務規格**：OpenSpec（proposal → specs GIVEN/WHEN/THEN → tasks → archive）。不再手寫一次性 prompt spec。
- **執行流程**：Superpowers skills（brainstorming → writing-plans → subagent-driven-development → TDD → 兩階段 code review → verification-before-completion）。子 agent 一律回短摘要、不倒全文，防灌爆主 context。
- **宣告測試通過／功能完成之前**：必過 `ops-playbooks:avoiding-false-green`（假綠缺口 checklist＋獨立驗證）。
- 高風險變動（金流/auth/導轉）另走 `/real-verify` 真瀏覽器閘門。

## Git 紀律（鐵則）

- **預設不自動 commit、不自動 push**。開啟條件：用戶說「幫我 commit」「開啟 auto-commit」「push」「開啟 auto-push」，僅限本 session。用戶說「跑到底/不用問我」時，第一步先問是否開 auto-push。
- **auto-push 開啟後＝batch-checkpoint 模式**：整批跑完一起彙報，小問題自行處理不中斷（review FAIL 一行明確修法→直接修；allowlist 擋→先加再重跑；1-2 個明確 test failure→修掉續跑）。**仍須停下**：刪除/覆蓋既有資料、不可逆外部操作、2+ 問題或架構決策、3+ 不明 failure。
- 跨 repo 操作一律 `git -C /absolute/path`，不用 `cd && git`（觸發 untrusted hooks 警告）。
- commit 衛生：上一批變更未 commit 前不混入下一批；commit 前 `git status` 核對檔案清單。
- commit 訊息省略 Co-Authored-By 註腳。

## 協作風格

- 方向/選型/規範類決策：先給分析＋推薦，再用 AskUserQuestion 選擇題確認。
- Claude 要跳過既定分工直接動手大改時，先說明原因並獲用戶確認。
- 含 `{ }` 的內容寫檔一律用 Write 工具，嚴禁 bash heredoc（觸發 expansion obfuscation 警告）。
- 嚴禁把 secret 實際值（key/token/密碼）輸出到終端或對話；確認存在用遮蔽值。

## 進度追蹤與記憶

- **永久待辦帳本**：`~/Desktop/架站計畫/01_前期規劃與設定/時程/17_進度追蹤/00_總覽_規則_待辦.md`（唯一跨 session 待辦入口）＋ `01_WeekN_每日.md`（新項目加最上面）。
- 更新時機：每輪任務完成後立即＋session 結束前；context 快滿時先把未完任務寫進帳本（附足夠 spec）再收。
- 進度追蹤、記憶、agent-ops 三邊不得矛盾，用 `/sync-status` 一鍵同步。
- Memory hygiene（畢業階梯、四槓桿、軟上限）→ 見 `~/Desktop/agent-ops/08_記憶與規則生命週期.md`。
