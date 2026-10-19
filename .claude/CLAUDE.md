# san-workflow 開發指引

這個 repo 同時是 Claude Code plugin 和 marketplace。內容只有 Markdown 和兩份 JSON manifest，沒有 build 或測試。

放在 `.claude/` 而不是根目錄，是因為根目錄的 `CLAUDE.md` 會讓 `claude plugin validate --strict` 失敗。

## commit 前的檢查

```bash
claude plugin validate --strict .   # manifest 與 marketplace 都要通過
claude --plugin-dir .               # 實際載入這份 checkout，試用 skills
```

- `marketplace.json` 的 source 是 `"./"`，使用者裝的是預設分支上的內容。
- `plugin.json` 的 `version` 會把使用者固定在快取版本：每次發布都要升版，並在 `CHANGELOG.md` 加一段。

## 結構

- `skills/<name>/`：安裝後的名稱是 `/san-workflow:<name>`。
- `rules/`：plugin 機制不能帶 rules，使用者依 README 手動複製到 `~/.claude/rules/san-workflow/`。
- `LICENSE`、`THIRD_PARTY_NOTICES.md`：衍生自其他專案的內容，要在 notices 列出來源，並保留該目錄的 `LICENSE`。

新增或移除 skill、rule 時，以下要一起更新：
- README 開頭的數量句、表格與結構樹；
- `plugin.json` 與 `marketplace.json` 的 description；
- 內容是衍生來的，`THIRD_PARTY_NOTICES.md` 也要更新。

## 從作者的本機設定同步

同步只做單向：本機設定 → 本 repo。

- **只複製檔案。** 不要 cherry-pick、subtree 或 format-patch 本機設定 repo 的 commit：那邊的 commit 用的是另一個身分，帶過來就會把它公開。
- **skills 原樣複製**，只有一個例外：`python-testing` 拿掉指向 `python-backend` 和 `rules/testing.md` 的引用，因為這兩者沒有收進本 repo。
- **rules 是公開版，手動改寫**，規則如下：
  - 剝掉來源檔裡的 HTML 註解標記，但保留 `git-workflow.md` 的授權來源註解；
  - 移除只適用於作者機器或雇主的內容（個人 `settings.json` 的設定現況、shell、公司政策）；
  - 引用到 hook 的地方，寫成「若有安裝」的通用建議；只描述個人 hook 行為、沒有通用建議價值的句子直接刪；
  - skill 一律用名稱引用，不寫 `skills/…/SKILL.md` 路徑；`workflow.md` 開頭保留 `san-workflow:` 前綴的說明。

## 公開內容檢查

這是 public repo。commit 前確認以下內容都不在 diff 裡：

- 個人絕對路徑（`/Users/...`、`/home/...`）和本機帳號名；
- 內部 IP、主機名、公司或內部專案名稱、客戶名稱；
- 公司信箱、token 或任何 secret。

```bash
git grep --untracked -n -e '/Users/' -e '/home/' -e '<!--' -- ':!.claude/CLAUDE.md'
```

預期只會命中兩處：`rules/security.md` 的 `/Users/<name>/` 佔位符，和 `rules/git-workflow.md` 的授權來源註解。

再掃 IP、信箱和本機帳號名（帳號名在執行時由 `whoami` 帶入，不寫進 repo）：

```bash
git grep --untracked -n -I -E -e '([0-9]{1,3}\.){3}[0-9]{1,3}' \
  -e '[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' -e "$(whoami)" -- ':!.claude/CLAUDE.md'
```

預期只命中 `skills/python-testing/SKILL.md` 的兩個範例信箱。有自備不受版控的客戶名單時，再用 `git grep --untracked -c -i -F -f <名單檔>` 確認是 0 筆。

## commit 慣例

- 格式是 `<type>: <description>`，type 用 `feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`。
- 不加 attribution trailer（Co-Authored-By、session 連結）。
- README 與 `CHANGELOG.md` 用繁體中文；skills 和 rules 沿用各檔原本的語言。
