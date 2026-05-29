---
name: docs-management
description: 開發文件管理系統 — feature docs、issue reports、tickets、handoff notes、changelogs 的建立與維護規則。任何 feat/fix/refactor commit、發現 bug、建立工作追蹤、session 結束交接、或功能完成更新 changelog 時，都必須使用此 skill。
---

# Documentation Management

管理 `docs/` 下的開發紀錄文件。`docs/` 供人類與 Claude Code 共用；`skills/*/docs/` 是 Claude 內部技術參考，兩者不混用。

## When to Activate

- Commit type 為 `feat:`、`fix:` 或 `refactor:` 且符合「When to Write Feature Docs」條件
- 發現 bug 或非預期行為
- 需要建立或更新工作追蹤
- Session 結束前有未完成工作需交接
- Feature complete 或 Issue fixed 時（更新 Changelog）

## Directory Structure

```
docs/
├── feat/
│   ├── <slug>/          ← Per-feature：feature docs + issues + tickets
│   └── _general/        ← 不屬於特定 feature 的 issues / tickets
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

- Feature slug 與 git branch name 對齊；一旦建立不改名
- Ticket 序號在 feature 目錄內遞增（不同 feature 可重複序號，以目錄區分）
- 不屬於特定 feature 的 issue / ticket 放入 `docs/feat/_general/`
- Issue slug 最多 5 個單字

## YAML Frontmatter（必要）

每個文件開頭必須有 frontmatter，從本 skill 目錄下的 `templates/`（與 SKILL.md 同層）複製對應 template 填入。下方各步驟所寫的 `templates/xxx.md` 皆指此目錄；user-level 安裝在 `~/.claude/skills/docs-management/templates/`，plugin 安裝則在 plugin cache 內對應目錄，請以實際 skill 目錄的絕對路徑為基準。
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

## Lifecycle & Status

| Type | Statuses |
|------|----------|
| Feature doc | `draft` → `in-progress` → `complete` |
| Issue | `open` → `investigating` → `fixed` / `wontfix` |
| Ticket | `backlog` → `in-progress` → `blocked` → `done` / `cancelled` |
| Handoff | 建立即完成，不刪除 |
| Changelog | 首次需要時建立，持續更新 |

## Cross-referencing

1. 文件間引用使用 **Markdown 相對路徑**
2. 雙向連結：A 引用 B 時，同步將 A 加入 B 的 `related` 陣列
3. `related` 路徑從 repo root 起算（如 `docs/feat/xxx/yyy.md`）
4. 正文中引用 commit 使用 6 字元 hash prefix

## Execution Steps

### 建立 Feature Doc

1. 複製 `templates/feature.md` 到 `docs/feat/<slug>/`
2. 以 commit hash 前 6 碼命名
3. 填入 frontmatter（commit 欄位用完整 40 字元 hash）
4. 撰寫 Overview、Changes Summary、Architecture Decisions
5. 更新相關文件的 `related` 欄位

### 建立 Issue

1. 複製 `templates/issue.md` 到相關 feature 資料夾
2. 命名為 `ISS-<YYYYMMDD>-<slug>.md`
3. 填入 severity、Root Cause、Fix
4. 修復後更新 `status: fixed` 與 `fixed-by`

### 建立 Ticket

1. `find docs/ -name "TKT-*.md"` 找到目前最大序號
2. 複製 `templates/ticket.md`，序號 +1
3. 放入相關 feature 資料夾

### 建立 Handoff

1. 複製 `templates/handoff.md` 到 `docs/handoff/`
2. 重點填寫：Current State、What's Left、Context for Next Session
3. 確保下一個 session 能獨立理解狀態

### 更新 Changelog

1. 確認 `docs/changelog/<YYYY-MM>.md` 存在，不存在則從 `templates/changelog-entry.md` 建立
2. Feature complete 或 Issue fixed 時新增對應條目
