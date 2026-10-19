# Development Workflow

> 本檔提到的 skill（`docs-management`、`spec-review`、`research` 等）由 san-workflow plugin 提供，
> 安裝後名稱帶 `san-workflow:` 前綴，例如 `/san-workflow:spec-review`。

## Pipeline
Research → Plan → TDD (Red/Green) → Code Review (含 Refactor) → Commit (+ Feature Doc & Changelog)

**Bug 走前置分支**：東西壞掉時不從 Research 進，改由 `diagnosing-bugs` 跑 Phase 1–4
（建紅燈迴路 → 重現最小化 → 排序假說 → 儀器化），拿到根因、量化影響範圍後收斂回 TDD 段，之後照常。
在 debug 情境，紅燈迴路建好之前就讀碼推理原因或上網找解法，是該 skill 明令要防的失敗；
為了建迴路而讀碼不在此限。

**不是 bug 也先找原因**：效能或行為不如預期、想調參數時，也先查清楚原因再提修法；
修根因，不要只壓住症狀。原因確認前保持唯讀。

**TDD 段**：寫測試前先叫起 `tdd-methodology`；紅燈測試必須從真實入口一路跑到這次改動的程式碼，
證明新程式碼真的會被執行到。

以下文件不受 pipeline 階段限制，符合條件即建立：
Issue report、Ticket、Handoff note、Research 報告

### Code Review 三軸，缺一不可
- `/code-review` — 品質與正確性
- `/security-review` — 安全軸；`/code-review` 不涵蓋深度安全檢查
- `/spec-review` — Spec 軸：漏做 / 超做（scope creep）/ 做錯

三者都由 Claude 依下方「兩個邊界」主動用 `/<name>` 明確叫起，**不要依賴自動觸發**；
發現分軸回報，**不互相合併排序**。
另有 `mr-docs-sync`（code → docs），與 `spec-review`（docs → code）方向相反、互補。

**`/security-review` 跑不起來時**：它以 `origin/HEAD` 為比較基準，缺這個 ref 就會失敗。
有 origin 的 repo 先用 `git remote set-head origin --auto` 補上；沒有 origin 的 repo，
改派 subagent 用明確的比較基準（例如 `git diff main...HEAD`）做安全審查，
基準若是本地分支，先提醒使用者它可能落後遠端。

#### 兩個邊界
- **批次收尾（可多次）** — `/code-review` + `/security-review`，並依 `docs-management` 落 feature doc。
- **MR 邊界（一次）** — 三軸跑滿（補 `/spec-review`），再跑 `mr-docs-sync`，
  且**必須排在 feature doc 落檔之後**（跑早了比對對象還不存在）。
  兩個邊界重疊時（分支本身就是一批票）合併跑一次。

## 先規劃後動工
非瑣碎的改動：先盤點現況、提出方案，等使用者說動工才實作。
瑣碎改動（錯字、意圖明確的單行修正、使用者明說「直接改」）不在此限。
需要使用者拍板的決策有兩個以上時，用 `grilling` 的格式逐輪討論（每輪最多 4 題，各附建議答案）。
動工後只做講好的範圍；範圍外的發現先講一句，不順手改。

## Docs
遵循 `docs-management` skill（baseline）。各 repo 的實際追蹤集合（尤其 `TKT-*` 是否版控）以該 repo `docs/docs-as-code.md` 為準。

| Doc Type | 觸發時機 |
|----------|---------|
| Feature doc | `feat:`/`fix:`/`refactor:` commit 符合 SKILL.md 條件時 |
| Issue report | 發現 bug 或非預期行為時 |
| Ticket | 需要追蹤待辦工作時 |
| Handoff note | Session 結束前有未完成工作時 |
| Changelog | Feature complete 或 Issue fixed 時 |
| Research 報告 | 動手前的調查需要沉澱、可回溯時 |
| `docs/CONTEXT.md` | 領域術語被釐清時（選用，lazily 建立） |

## Research & Reuse (mandatory before new implementation)

**執行者 = `research` skill**（在地化自 mattpocock/skills）。
調查範圍大時由它開 background agent 去讀，主線可以繼續進行；幾次查詢就能回答的問題直接查。
落檔委派 `docs-management`。
本段是判準，不是流程——流程在那個 skill 裡。

- WebSearch / WebFetch 搜尋現有方案
- Library docs: Context7 MCP（僅在專案有配置時）；否則 WebFetch 官方文件
- Check package registries (npm, PyPI) before writing utilities
- Prefer adopting proven approaches over net-new code
- 調查值得回溯時，依 `docs-management` 落成 `research-<YYYYMMDD>-<slug>.md`（逐節標一手來源）

> **不適用於 debug**：東西壞掉時，紅燈迴路建好之前就讀碼推理原因或上網找解法，正是 `diagnosing-bugs`
> Phase 1 明令要防的失敗（為了建迴路而讀碼不在此限）。見本檔開頭「Bug 走前置分支」。

## 委派 subagent
- 依規模決定：幾次工具呼叫就能查完的自己查；大範圍、可平行、彼此獨立的調查才派 subagent。
- 調查與審查的 subagent 沿用主模型。範圍清楚的簡單實作派給 subagent 時，指定 `model: sonnet`、
  `effort: medium`；子任務跨多個檔案或步驟多時改用 `high`；不用 `low`（容易略過驗證、做到一半就停下來問）。
- 派實作 subagent 時，在 prompt 附上這兩段（Sonnet 5.5 官方提示指南原文）：

  > Keep working until everything the user asked for is done, and only stop to ask when you can't go on without the user or before a risky step.
  >
  > When the work the user asked for is done and checked, stop and report. Don't add features, tests, files, docs or refactors that weren't asked for. If you think one would help, mention it at the end instead of doing it.

## Verify Before Assert
下結論前先列出關鍵假設，對真實資料/一手來源驗證後才斷言；宣稱某緩解/設定已生效前，複核實際狀態。
無法直接驗證的論斷明確標註。數字比較須同組態對齊，不引用未經核對的舊數。

**二手結論不得穿一手的衣服。** sub-agent 的報告、research 文件、前一個 session 的結論，
都不是一手來源。轉述它們可以，但要講明白是轉述；不要為二手內容套用一手查證的格式
——`file:line` 引用、「實測」、「官方文件明寫」都會讓讀者以為你親自看過。
要用那個格式，就先自己去看。

對系統行為下論斷前（並行或串行、設定值、容量、支不支援），先查實際設定和正在執行的版本
（哪個分支、哪個 commit），不要憑記憶或文件推論。建議會清掉資料的操作前，先確認它會不會清。
引用數字時講明來自哪台機器、哪個組態；測試條件依實際跑到的內容命名。
只補測了部分條件時，不宣稱整體可信；安全宣稱只講閘門實際涵蓋的範圍。
使用者質疑某個論斷時，先回頭查證，不要先辯護。

## Output Discipline
長產出（報告、盤點、大量程式碼）分批寫入檔案再彙總，不在單一回覆一次輸出；
預期超過數百行時先寫檔。

## Plain-Language Explanation
說明技術改動、發現與取捨時用白話，不堆術語；術語與程式碼識別字保留原文，
但每個關鍵概念要有一句人話解釋它「是什麼、為什麼重要」。
先講結論與影響，再講機制；不要求讀者自行從實作細節反推結論。
互動審查時一次講一個 commit：改了什麼、為什麼這樣改。

## 需要使用者決定的問題
多個需要使用者決定的問題，用文字列出並各附建議答案；不要用 AskUserQuestion 對話框問長段落的題目。

## 動工前的平行檢查
在多人共用的 repo 接續工作前（尤其是接手別人的分支或 MR），先 `git fetch --all`，
看 origin 上的分支與近期 commit。同事可能已經把同一個修法推上去了。

另一個 session（平行的 Claude、或人）正在處理 review 或相關工作時，
不要 commit、也不要建立會重疊的文件。

## 長時間任務與 shell
- 每次執行用自己專屬的 log 檔或完成標記檔（例如帶時間戳的 log、`.done`／`.failed`），不 grep 共用的 log。
- 輪詢只看這次啟動之後寫入的輸出；比對到舊的失敗行不算結束。
- 啟動前一次檢查完所有相依（函式庫、版本），缺什麼一次回報，不要邊跑邊補。
- 傳給腳本與子程序的路徑一律用絕對路徑。
- shell 是 zsh 時：沒加引號的變數不會依空白拆開，依賴拆字的指令改用陣列或 `bash -c`。
- 需要無人值守地跑到完成時，用 `/goal` 寫一個可驗證的完成條件，並用清單檔追蹤進度。
