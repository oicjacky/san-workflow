# san-workflow

一套 Claude Code 開發工作流，包成 plugin 方便團隊共用。

包含 10 個 skills 和 5 份全域 rules，覆蓋「研究 → 規劃 → TDD → 三軸 Code Review → Commit 與文件」整條管線。

## 安裝

需要支援 plugin 系統的 Claude Code（建議最新版）。

```text
# 1. 在 Claude Code 中註冊 marketplace
/plugin marketplace add oicjacky/san-workflow

# 2. 安裝 plugin
/plugin install san-workflow@san-marketplace
```

`owner/repo` 的寫法會先試 SSH。沒有設定 GitHub SSH key 的機器，在 session 裡用 `/plugin` 安裝或更新時不會自動改走 HTTPS，請先在 shell 設 `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` 再啟動 Claude Code。

### 手動安裝 rules（建議）

plugin 機制不能帶 rules，所以要手動複製。`~/.claude/rules/` 底下的 `.md`（含子目錄）會自動載入，不需要在 `CLAUDE.md` 加 `@import`。放在子目錄，就不會蓋掉你原本同名的 rules：

```bash
tmp=$(mktemp -d) &&
  git clone --depth 1 https://github.com/oicjacky/san-workflow.git "$tmp" &&
  mkdir -p ~/.claude/rules/san-workflow &&
  cp "$tmp"/rules/*.md ~/.claude/rules/san-workflow/ &&
  rm -rf "$tmp"
```

這些 rules 有明確立場（例如 commit 前先等使用者審查、未經授權不 push），安裝前請先讀過，不需要的段落直接刪掉。沒有裝 `workflow.md` 的話，skills 仍可手動叫起，但 `docs-management` 等 skill 的觸發時機（哪種 commit 要寫哪種文件）會失效。

## 內容清單

### Skills（10）

安裝後的名稱帶前綴，例如 `/san-workflow:spec-review`。

| Skill | 用途 |
|-------|------|
| `docs-management` | 開發追蹤文件的建立與維護：feature doc、issue、ticket、handoff、changelog、research 報告、`docs/CONTEXT.md` |
| `mr-docs-sync` | 發 MR／PR 前，檢查本分支的程式碼改動是否都已反映在文件與 changelog（只讀、回報落差） |
| `spec-review` | Review 的 Spec 軸：比對程式碼改動與規格文件，找出漏做、超做、做錯 |
| `research` | 依一手來源調查問題，結果寫成 repo 裡的 research 報告 |
| `tdd-methodology` | 什麼算好的測試、seam 怎麼切、常見反模式 |
| `diagnosing-bugs` | 難解 bug 與效能退化的診斷流程：先建紅燈迴路，再重現、排序假說、儀器化，最後收斂回 TDD |
| `codebase-design` | 設計「深模組」的共用詞彙：介面怎麼設計、哪裡可以做深、seam 放在哪 |
| `grilling` | 針對計畫或決策逐題追問，壓力測試想法 |
| `python-testing` | pytest 的 fixtures、mocking、參數化、async 測試 |
| `python-quality-gates` | Python 測試目錄結構、80% 覆蓋率閘門、CI 串接、發 PR 前的檢查清單 |

### Rules（5，手動安裝）

| 檔案 | 內容 |
|------|------|
| `workflow.md` | 開發管線、Bug 前置分支、三軸 Code Review、先規劃後動工、Verify Before Assert |
| `git-workflow.md` | Commit 格式與拆分、Review Before Commit、分支與 MR、衝突處理、授權邊界 |
| `docs-and-comments.md` | 註解、commit message、MR 描述的寫法 |
| `security.md` | 機密處理、受版控檔案不放個人與基礎設施資訊、客戶名稱不進版控 |
| `python.md` | Python 環境、慣用寫法（讀寫 `.py`／`.pyi` 檔時才載入） |

## 工作流概覽

```
Research → Plan → TDD (Red/Green) → Code Review（含 Refactor）→ Commit
  │                                  │                          │
  research                           /code-review（內建）        docs-management
  grilling                           /security-review（內建）    mr-docs-sync（發 MR 前）
                                     spec-review
Bug：diagnosing-bugs 找到根因 → 收斂回 TDD
```

`docs/` 目錄結構（由 `docs-management` 規範）：

```
docs/
├── feat/<slug>/        ← feature doc、issue、ticket、research 報告
├── feat/_general/      ← 不屬於特定 feature 的 issue 和 ticket
├── handoff/            ← 跨 session 交接
├── changelog/<YYYY-MM>.md
└── CONTEXT.md          ← 領域詞彙表（選用）
```

## Plugin 結構

```
san-workflow/
├── .claude-plugin/
│   ├── plugin.json           ← plugin manifest
│   └── marketplace.json      ← marketplace 註冊（source 指向 repo 根目錄）
├── skills/                   ← 10 個 skills
├── rules/                    ← 5 份全域 rules（手動安裝）
├── CHANGELOG.md
├── LICENSE
├── THIRD_PARTY_NOTICES.md
└── README.md
```

## 更新

在 shell 執行下列指令，或在 session 裡開 `/plugin`，從 Installed 分頁選 san-workflow → **Update now**：

```bash
claude plugin update san-workflow@san-marketplace
```

plugin 只在版號改變時更新。rules 不會跟著更新，要再跑一次上方「手動安裝 rules」的指令。

## 疑難排解

- **skill 沒有自動觸發**：確認 rules 已複製到 `~/.claude/rules/` 底下。
- **同名 skill 出現兩份**：如果你同時啟用了 mattpocock 的 skills plugin，或在 `~/.claude/skills/` 有同名的個人 skill，兩份都會載入、各自佔用 context。建議只留一份。
- **從 0.1.x 升級**：0.2.0 移除了 8 個 subagents、`ticket-loop` 和 `tdd-workflow`，細節見 [CHANGELOG.md](CHANGELOG.md)。rules 也要搬家：
  1. 刪掉 0.1.x 複製到 `~/.claude/rules/` 頂層的 `workflow.md`、`git-workflow.md`、`python.md`（自己改過的話先備份）。
  2. 刪掉 `~/.claude/CLAUDE.md` 裡的 `@rules/workflow.md`、`@rules/git-workflow.md`、`@rules/python.md` 三行。
  3. 依上方「手動安裝 rules」重新安裝到 `~/.claude/rules/san-workflow/`。

## 授權

MIT，見 [LICENSE](LICENSE)。部分內容改寫自其他 MIT 授權的專案，版權聲明見 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
