---
name: docs-management
description: 開發追蹤文件（feature doc、issue report、ticket、handoff、changelog、research 報告）的建立與維護規則。任何 feat/fix/refactor commit、發現 bug、建立工作追蹤、session 交接、功能完成（changelog）、或產出調查報告時，都必須使用此 skill。
---

# Documentation Management

管理 `docs/` 下的開發紀錄文件。`docs/` 供人類與 Claude Code 共用；`skills/*/docs/` 是 Claude 內部技術參考，兩者不混用。

> **專案可覆寫（本 skill 為 baseline 預設）**：各 repo 的實際追蹤集合以該 repo `docs/docs-as-code.md` 為準（若有）。常見覆寫：`TKT-*` 降級為**本地 scratch、不版控**；新增 `ANALYSIS.md` / `DESIGN.md`（架構決策，含「拍板記錄」）為**選用** feature 文件。`docs/CONTEXT.md`（領域詞彙表）與 `research-*.md` 亦為**選用**，需要時才建。

## When to Activate

- Commit type 為 `feat:`、`fix:` 或 `refactor:` 且符合「When to Write Feature Docs」條件
- 發現 bug 或非預期行為
- 需要建立或更新工作追蹤
- Session 結束前有未完成工作需交接
- Feature complete 或 Issue fixed 時（更新 Changelog）
- 動手前對某主題做過調查、需要沉澱成可回溯的報告
- 討論到領域術語、發現用詞衝突或含糊（見「領域詞彙表」）

## Directory Structure

```
docs/
├── CONTEXT.md           ← 領域詞彙表（選用，lazily 建立；全 repo 唯一一份）
├── feat/
│   ├── <slug>/          ← Per-feature：feature docs + issues + tickets + research
│   └── _general/        ← 不屬於特定 feature 的 issues / tickets / research
├── handoff/             ← 跨 session 交接筆記
└── changelog/           ← 月度 changelog
```

## Naming Rules

| Type | Format | Example |
|------|--------|---------|
| Feature slug | `<lowercase-hyphen>` | `observer-summarizer-v2` |
| Feature doc | `<6-char-hash>.md` | `283fd2.md` |
| Issue | `ISS-<YYYYMMDD>-<slug>.md` | `ISS-20260403-orphan-observer.md` |
| Ticket | `TKT-<NNN>-<slug>.md` | `TKT-001-add-temporal-patterns.md` |
| Handoff | `<YYYYMMDD>-<slug>.md` | `20260403-observer-defense.md` |
| Changelog | `<YYYY-MM>.md` | `2026-04.md` |
| Research | `research-<YYYYMMDD>-<slug>.md` | `research-20260411-http-retry-libraries.md` |
| 詞彙表 | `docs/CONTEXT.md`（固定路徑，全 repo 一份） | — |

- Feature slug 與 git branch name 對齊；一旦建立不改名
- Feature doc 以該 feature **第一個 commit** 的 sha 前 6 碼命名（穩定、可提早建檔；檔名只是 handle，內容 as-built 涵蓋整個 MR 的所有 commit）
- Ticket 序號在 feature 目錄內遞增（不同 feature 可重複序號，以目錄區分）
- 不屬於特定 feature 的 issue / ticket / research 放入 `docs/feat/_general/`
- Issue slug 最多 5 個單字
- Research 報告放進它所服務的 feature 資料夾；跨 feature 或先於 feature 的調查放 `_general/`

## YAML Frontmatter（必要）

每個文件開頭必須有 frontmatter，從 `${CLAUDE_SKILL_DIR}/templates/` 複製對應 template 填入。
必填欄位以各 type 的 template 定義為準。

注意事項：
- Template 中 `status: draft | in-progress | complete` 等 pipe 分隔選項，填入時**替換為單一值**（如 `status: draft`）
- 無 cross-reference 時寫 `related: []`
- `commit` 與 `fixed-by` 欄位使用完整 40 字元 hash
- `branch` 欄位填入實際 branch 名稱（如 `main` 或 `feat/xxx`）

## When to Write Feature Docs（Commit-time 強制）

符合任一條件時必須建立 feature doc：

- 新增或刪除檔案
- 變更架構決策
- 修改公開 API 或介面
- 修改超過 50 行程式碼
- 修復 HIGH severity issue

不需要：純 typo、格式化調整、一般依賴升級。

## 決策記錄門檻（ADR 三條件）

> 來源：[mattpocock/skills](https://github.com/mattpocock/skills) `domain-modeling` @ 1.2.0（`ed37663c`，MIT）的 ADR 判準，在地改寫為適用本專案的「拍板記錄」。**不另開 `docs/adr/` 目錄**——決策繼續寫在該 feature 的 `DESIGN.md`。

決策記錄的問題從來不是格式，是**門檻**。沒有門檻就會濫寫（每個選擇都記）或漏寫（重大取捨沒人記）。

**三條件全中才值得寫進 `DESIGN.md` 的「拍板記錄／決策紀錄」段落：**

1. **難逆轉** — 之後改主意的代價是實質的。容易改的就別記，反正你會改。
2. **沒背景會困惑** — 未來的讀者看到程式碼會問「為什麼要這樣做？」。不讓人意外的，沒人會問。
3. **真有取捨** — 當時存在其他可行選項，你為了具體理由選了這個。沒有替代方案就只是「做了顯而易見的事」，沒東西可記。

**缺一不寫。**

典型該記的：架構形狀（單體 / 拆服務、寫入模型）· 跨模組的整合方式（事件 vs 同步呼叫）· 有 lock-in 的技術選型（DB、訊息佇列、雲廠商——不是每個 library，是換掉要花一季的那種）· 邊界與範圍（誰擁有哪份資料）· **刻意偏離顯而易見做法**（「用手寫 SQL 不用 ORM，因為 X」——這類最重要，能阻止下一個人把刻意的設計「修好」）· 程式碼看不出的外部約束（法遵、SLA、合約）· 非顯而易見的否決理由。

記錄格式沿用既有慣例：帶**日期**與**拍板來源**（如「2026-07-07 與使用者討論定案」），保持可稽核。

## 領域詞彙表（`docs/CONTEXT.md`）

> 來源同上（`domain-modeling` @ 1.2.0）。**單一 context**：全 repo 只有一份 `docs/CONTEXT.md`，不做多 context / `CONTEXT-MAP.md`。

**選用、lazily 建立**——第一個術語被釐清時才建檔，不預先建空殼。建立後 `tdd-methodology`、`diagnosing-bugs`、`codebase-design` 都會讀它來對齊命名。

### 對話中的行為（這是主動的，不是等人來查）

- **對照詞彙表挑錯**：使用者用的詞與 `docs/CONTEXT.md` 既有定義衝突時，**當下就提出**——「詞彙表把『取消』定義為 X，但你這裡像是指 Y，哪個才對？」
- **把含糊的詞磨利**：遇到模糊或一詞多義，提出精確的正典用詞——「你說『帳號』，指的是客戶還是使用者？這是兩件事。」
- **用具體情境壓測**：討論到概念之間的關係時，主動造邊界情境，逼出概念之間的界線。
- **跟程式碼對照**：討論需求或設計時，若使用者對系統行為的描述會影響決定，確認程式碼是否同意。矛盾就攤開來——「程式碼是整張訂單取消，但你剛說可以部分取消，哪個是對的？」
- **當場更新，不要累積**：術語一釐清就立刻寫進 `docs/CONTEXT.md`。

### 格式

```md
# {專案／領域名稱}

{一兩句：這個領域是什麼、為什麼存在。}

## Language

**訂單（Order）**：
{一兩句定義它「是什麼」，不是「做什麼」。}
_避免_：採購、交易

**發票（Invoice）**：
出貨後向客戶請款的單據。
_避免_：帳單、請款單
```

規則：

- **要有主張**。同一概念有多個講法時，挑最好的當正典，其餘列進 `_避免_`。
- **定義要短**。一到兩句。定義它「是什麼」，不是「做什麼」。
- **只收這個專案特有的概念**。通用程式概念（timeout、錯誤型別、工具函式模式）不收，即使專案大量使用。加詞前先問：這是本領域獨有的，還是通用程式概念？只有前者該進來。
- `docs/CONTEXT.md` **只是詞彙表**。不放實作細節、不當規格、不當草稿本——那些屬於 `DESIGN.md`。
- 術語多到自然形成群集時再用次標題分組；同一個領域內平鋪即可。

## Lifecycle & Status

| Type | Statuses |
|------|----------|
| Feature doc | `draft` → `in-progress` → `complete` |
| Issue | `open` → `investigating` → `fixed` / `wontfix` |
| Ticket | `backlog` → `in-progress` → `blocked` → `done` / `cancelled` |
| Handoff | 建立即完成，不刪除 |
| Changelog | 首次需要時建立，持續更新 |
| Research | `in-progress` → `complete`（結論已可據以行動）→ `superseded`（被更新的調查取代） |
| 詞彙表 | 無 status，持續增修 |
| 決策記錄（`DESIGN.md` 拍板記錄） | 每條標**日期**與拍板來源；被後續決策推翻時**不刪舊條目**，補一條新的並在舊條目標「已由 YYYY-MM-DD 的 D<NN>（拍板記錄的流水編號，例如 D12）取代」 |

## Cross-referencing

1. 文件間引用使用 **Markdown 相對路徑**
2. 雙向連結：A 引用 B 時，同步將 A 加入 B 的 `related` 陣列
3. `related` 路徑從 repo root 起算（如 `docs/feat/xxx/yyy.md`）
4. 正文中引用 commit 使用 6 字元 hash prefix

## Execution Steps

### 建立 Feature Doc

1. 複製 `${CLAUDE_SKILL_DIR}/templates/feature.md` 到 `docs/feat/<slug>/`
2. 以 commit hash 前 6 碼命名
3. 填入 frontmatter（commit 欄位用完整 40 字元 hash）
4. 撰寫 Overview、Changes Summary、Architecture Decisions
5. 更新相關文件的 `related` 欄位

### 建立 Issue

1. 複製 `${CLAUDE_SKILL_DIR}/templates/issue.md` 到相關 feature 資料夾
2. 命名為 `ISS-<YYYYMMDD>-<slug>.md`
3. 填入 severity、Root Cause、Fix
4. 修復後更新 `status: fixed` 與 `fixed-by`

### 建立 Ticket

1. `find docs/ -name "TKT-*.md"` 找到目前最大序號
2. 複製 `${CLAUDE_SKILL_DIR}/templates/ticket.md`，序號 +1
3. 放入相關 feature 資料夾

### 建立 Handoff

1. 複製 `${CLAUDE_SKILL_DIR}/templates/handoff.md` 到 `docs/handoff/`
2. 重點填寫：Current State、What's Left、Context for Next Session
3. 確保下一個 session 能獨立理解狀態

### 建立 Research 報告

1. 複製 `${CLAUDE_SKILL_DIR}/templates/research.md`，命名 `research-<YYYYMMDD>-<slug>.md`
2. 放進所服務的 `docs/feat/<slug>/`；跨 feature 或先於 feature 的放 `docs/feat/_general/`
3. 開頭寫明**目的**：這份調查要支撐哪個決定（例如「在實作 TKT-002~005 之前，評估兩項方案的技術可行性」）
4. **逐節標一手來源**——官方文件、原始碼、規格、第一方 API，不引用二手轉述。每條主張都能追回擁有它的來源
5. 結論要能據以行動：明確寫出「建議採用 / 不採用 X，因為 Y」，並在 `related` 連到後續的 `TKT-*`——
   依 Cross-referencing 規則 #2，**同步把本報告加進該 `TKT-*` 的 `related`**（雙向）
6. 被更新的調查取代時，更新 `status: superseded` 並連到取代它的那份

### 維護領域詞彙表

1. 首次釐清術語時才建 `docs/CONTEXT.md`（不預先建空殼）
2. 依「領域詞彙表」段的格式寫入，一次一個術語，當場更新
3. 只收本領域特有概念；通用程式概念不收

### 更新 Changelog

1. 確認 `docs/changelog/<YYYY-MM>.md` 存在，不存在則從 `${CLAUDE_SKILL_DIR}/templates/changelog-entry.md` 建立
2. Feature complete 或 Issue fixed 時新增對應條目
