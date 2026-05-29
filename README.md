# san-workflow

sanhuang 日常使用的 Claude Code 開發工作流，包成 plugin 方便團隊共用。

包含 3 個 skills、8 個自訂 subagents、3 份全域 rules，覆蓋完整的「文件管理 → 待辦追蹤 → TDD → Code Review → Commit」管線。

## 安裝

需要 Claude Code 支援 plugin 系統的版本（建議最新版）。

```text
# 1. 在 Claude Code 中註冊 marketplace
/plugin marketplace add oicjacky/san-workflow

# 2. 安裝 plugin
/plugin install san-workflow@san-marketplace
```

> Plugin 與 marketplace 在同一個 repo 的 root，所以指令直接指向 repo 即可。

### 手動安裝 rules（必要）

Plugin 機制目前不支援自動寫入 `~/.claude/rules/`。請手動：

```bash
git clone https://github.com/oicjacky/san-workflow.git /tmp/san-workflow
mkdir -p ~/.claude/rules
cp /tmp/san-workflow/rules/*.md ~/.claude/rules/
```

然後在 `~/.claude/CLAUDE.md` 加入：

```markdown
@rules/workflow.md
@rules/git-workflow.md
@rules/python.md
```

沒有這一步，`docs-management` 的觸發時機（pipeline、commit-type 對應 doc）會失效。

## 內容清單

### Skills（3）

| Skill | 用途 |
|-------|------|
| `docs-management` | 開發文件管理：feature docs、issues、tickets、handoff、changelog |
| `ticket-loop` | 批次掃描並執行 `docs/` 下未完成 tickets（planner → agents → architect pipeline）|
| `tdd-workflow` | Test-Driven Development 流程（Red/Green/Refactor + 80%+ coverage）|

### Custom Subagents（8）

| Agent | 任務 |
|-------|------|
| `architect` | 系統架構審查、技術決策 |
| `code-reviewer` | Code quality / 維護性審查 |
| `doc-updater` | 文件與 codemap 更新 |
| `e2e-runner` | E2E 測試生成與執行 |
| `planner` | 複雜功能的執行計畫 |
| `refactor-cleaner` | 死碼移除、重構整理 |
| `security-reviewer` | OWASP / 漏洞檢測 |
| `tdd-guide` | TDD 流程引導 |

`ticket-loop` 會根據 ticket 內容自動選擇對應 agent。

### Global Rules（3，手動安裝）

| File | 內容 |
|------|------|
| `workflow.md` | Pipeline：Research → Plan → TDD → Review → Commit |
| `git-workflow.md` | Commit message 格式（type: description）與 PR workflow |
| `python.md` | Python 專案特定規範 |

## 工作流概覽

```
Research → Plan → TDD (Red/Green/Refactor) → Code Review → Commit
                                                            │
                                                            ├── docs-management（自動建 feature doc / 更新 changelog）
                                                            └── ticket-loop（後續批次清待辦）
```

`docs/` 目錄結構（由 docs-management 規範）：

```
docs/
├── feat/<slug>/        ← feature docs + issues + tickets
├── feat/_general/      ← 不屬於特定 feature 的 issues/tickets
├── handoff/            ← 跨 session 交接
└── changelog/<YYYY-MM>.md
```

## Plugin 結構

```
san-workflow/
├── .claude-plugin/
│   ├── plugin.json           ← plugin manifest
│   └── marketplace.json      ← marketplace 註冊
├── skills/
│   ├── docs-management/
│   │   ├── SKILL.md
│   │   └── templates/        ← 5 個 doc templates
│   ├── ticket-loop/
│   │   └── SKILL.md
│   └── tdd-workflow/
│       └── SKILL.md
├── agents/                   ← 8 個 .md
├── rules/                    ← 3 份全域 rules（手動安裝）
├── README.md
└── .gitignore
```

## 使用範例

安裝完成後，在任何專案中：

```text
# 1. 啟動新功能（Claude 會引導 TDD 流程）
你想做什麼新功能？

# 2. 累積 tickets 後批次處理
/san-workflow:ticket-loop

# 3. Commit 時自動觸發 docs-management
（根據 commit type 自動建立 feature doc 與更新 changelog）
```

> Plugin 安裝後，skill 會帶有 namespace：`/san-workflow:ticket-loop`、`/san-workflow:docs-management` 等。

## 疑難排解

- **Skill 沒自動觸發**：確認 `~/.claude/rules/` 已放入 rules 且 CLAUDE.md 有 @import
- **`ticket-loop` 找不到 ticket**：先用 `docs-management` 建立至少一個符合命名格式的 `TKT-NNN-<slug>.md`
- **Agent 找不到**：確認 plugin 安裝成功（`/plugin list`），agents 應自動可用
- **更新 plugin**：`/plugin update san-workflow`

## 授權

依 sanhuang 個人開發習慣整理，僅供團隊內部參考使用。
