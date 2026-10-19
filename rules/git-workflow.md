# Git Workflow

## Commit Message Format
```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

Note: 要停用 commit 與 PR 的 attribution，在 `~/.claude/settings.json` 把 `attribution` 的 `commit`、`pr` 設為空字串。

## Commit Separation
docs/ 下的追蹤文件（`TKT-*`、`ISS-*`、handoff、changelog 等）一律獨立 `docs:` commit，
不與程式碼混入同一 commit。

## Review Before Commit
套用變更後保持 uncommitted，等使用者審查；僅在使用者明確要求時才 commit
（agents / pipeline 的產出亦同，不自行 commit）。

## 後續修正與 amend
後續修正預設開新 commit。修正屬於某個還沒 push 的 commit 時，提一句可以折回去
（`fixup` 加上 `rebase --autosquash`），使用者同意才折。已 push 的 commit 不改寫。

## 分支與 MR
- 開新分支前先 `git fetch`，從最新的 `origin/<base>` 建立；本地的 base 分支可能已經落後，不從它建立。
- 處理途中發現另一個獨立問題時，另開分支處理，並依 `docs-management` 建立 `ISS-*`。
- 每個 commit 只做一件事；會影響其他團隊的改動放在獨立的 commit，讓他們可以單獨 review。
- 彼此緊密相關的改動放在同一個 MR，不為了分開追蹤而拆成多個 MR。

## Merge / Rebase 衝突處理
<!-- 改寫自 mattpocock/skills resolving-merge-conflicts (MIT)。放 rules 不放 skill：衝突當下 context 是「執行指令」，靠 skill 觸發會漏 -->

1. **先看清楚狀態**：git history 與衝突檔案，理解這是 merge 還是 rebase、雙方各是什麼。
2. **追每個衝突的一手來源**：讀 commit message、對應的 MR / PR、原始 issue / `TKT-*`，
   弄懂**兩邊各自為什麼那樣改**。不確定原意就不要動那個 hunk。
3. **逐 hunk 解**：盡量保留雙方意圖；真的不可調和時，選符合**這次 merge 目標**的那邊，
   並把取捨寫進 commit message。**不發明新行為**——衝突解決不是重構的時機。
4. **永不 `--abort`**。攔截危險 git 指令的 hook 通常不攔 `--abort`，這條靠自律。
   卡住就停下來問，不要靠放棄來脫身。
5. 跑專案的自動檢查（typecheck → tests → format），修掉 merge 弄壞的部分，再完成 merge / rebase。

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft a PR summary sized to the change
4. Include test plan with TODOs
5. Push only when the user has authorized it (see 授權邊界 below); use `-u` for new branches

> For the full development process (planning, TDD, code review) before git operations,
> see [workflow.md](./workflow.md).

## 授權邊界
未經使用者明確授權，不得：

- **push 到 remote** —— MR 由使用者本人 push 與發布；agent 只負責草擬 MR 描述
- **套用 DB migration** —— agent 只建立 migration 檔
- 執行耗用大量運算資源的工作、存取私人資料
- 執行難以回復的操作：刪除資料或模型檔、為了回收資源而 kill process、
  以 `git rm` / `rm -rf` 移除 tracked 原始檔

若有安裝攔截危險 git 指令的 hook（例如擋 `reset --hard`、force-push、`clean -f`），
上面這幾項通常**不在它的清單內**，仍要靠這條規則。
