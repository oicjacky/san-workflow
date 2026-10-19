# Changelog

## 0.2.0

### 不相容的改動

- 移除 8 個 subagents（`architect`、`code-reviewer`、`doc-updater`、`e2e-runner`、`planner`、`refactor-cleaner`、`security-reviewer`、`tdd-guide`）。Code review 改用內建的 `/code-review`、`/security-review` 加上 `spec-review` skill，規劃改用內建的 Plan mode。
- 移除 `ticket-loop`。它依賴上述 subagents。
- 移除 `tdd-workflow`，改由 `tdd-methodology`、`python-testing`、`python-quality-gates` 分層取代。
- rules 改成複製到 `~/.claude/rules/san-workflow/`，不再需要在 `~/.claude/CLAUDE.md` 加 `@import`。升級時要刪掉 0.1.x 放在 `~/.claude/rules/` 頂層的三份 rules 和那三行 `@rules/...`，步驟見 README 的「從 0.1.x 升級」。

### 新增

- Skills：`spec-review`、`research`、`tdd-methodology`、`diagnosing-bugs`、`codebase-design`、`grilling`、`python-testing`、`python-quality-gates`。
- Rules：`docs-and-comments.md`、`security.md`。
- `LICENSE`（MIT）和 `THIRD_PARTY_NOTICES.md`。

### 修正與更新

- `mr-docs-sync`：改用三點 diff（`<base>...HEAD`）。以前用兩點 diff，分支落後 base 時，base 上新增的檔案會被誤報成本分支的改動。
- `docs-management`：新增 research 報告、`docs/CONTEXT.md` 詞彙表和決策記錄門檻；handoff 範本改用 repo 相對路徑。
- `workflow.md`、`git-workflow.md`、`python.md` 同步到現行版本。
- marketplace 改用 `"./"` 指向 repo 根目錄。

## 0.1.1

- 4 個 skills（`mr-docs-sync` 是在同一個版號下後補的）、8 個 subagents、3 份 rules。
