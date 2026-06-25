---
name: mr-docs-sync
description: 發 MR / PR 前(或被要求「檢查文件是否同步」「docs-as-code 檢查」時),驗證本分支相對 base 的程式碼改動是否都已反映在該 feature 的版控文件(feature doc <sha>.md / DESIGN.md / ANALYSIS.md)與 changelog。回報落差並提出補寫建議。只讀+回報,不自動改文件,除非使用者要求。
---

# MR Docs-Sync Check

確保「docs-as-code」:MR 的程式碼改動必須反映在版控的 feature 文件,讓 reviewer 只讀文件就能掌握全貌。

## When to Activate

- 即將開 / 更新 MR / PR。
- 使用者說「檢查文件是否同步」「docs 有沒有跟上 code」「docs-as-code 檢查」。
- 完成一段功能、commit 後想確認文件完整性。

## 追蹤模式（預設,可被專案 CLAUDE.md 覆寫）

每個 feature 在 `docs/feat/<slug>/` 下版控。**必要**:`docs/changelog/<YYYY-MM>.md` + `<feature 第一個 commit 的 sha[:6]>.md`(feature doc,as-built)。**選用**:`ANALYSIS.md`(現況盤點)、`DESIGN.md`(架構決策)——存在才一併對照。先讀專案 `docs/docs-as-code.md`(若無則 `CLAUDE.md`)確認該 repo 的實際追蹤規則(例如某些 repo 不追蹤 `TKT-*`,或 CLAUDE.md 本身不追蹤)。

## Steps

1. **定位 base 與 diff(只取已 commit,不含 working-tree)**
   - base 分支依 repo 而定(`origin/dev` / `origin/main` / `origin/master`);可由 `git rev-parse --abbrev-ref --symbolic-full-name @{u}` 或常見命名推定,不確定就問使用者。
   - 程式碼改動:`git diff <base> HEAD --stat -- ':!docs/'`(兩點 diff = 本分支領先 base 的淨改動)。
   - 文件改動:`git diff <base> HEAD --stat -- 'docs/'`。

2. **找到 feature 文件夾**
   - 由分支名 → slug,對應 `docs/feat/<slug>/`。
   - 找出 feature doc(該資料夾內非 ANALYSIS/DESIGN 的 `<6hex>.md`)、對應月份 `docs/changelog/<YYYY-MM>.md`,以及選用的 `ANALYSIS.md` / `DESIGN.md`(若存在)。
   - 若缺 feature doc 或 changelog 條目 → 直接列為落差(此二者必要);ANALYSIS/DESIGN 缺席不算落差,但存在就要對照其內容是否過時。

3. **逐項對照(code → docs)**,讀上述文件後檢查:
   - **檔案覆蓋**:每個變動的 code 檔(`.py`/`.sql`/…)是否出現在 feature doc 的 **Changes Summary**(New/Modified Files)。漏列 = 落差。
   - **反向(stale)**:feature doc 列了但本 MR 未動的檔 = 過時描述。
   - **行為/介面變更**:diff 中的新增/移除函式、改變的公開介面、schema/migration、預設值、break 行為,是否在 **DESIGN(架構決策)** 或 feature doc 有對應說明。沒有 = 落差。
   - **migration / DB**:新增的 `sql/migrations/NNN__*.sql`、view/proc 改動,是否在文件反映(含正確的 migration 編號)。
   - **Breaking change**:有破壞性行為(移除/翻轉判定/改 API)是否寫進 changelog 的 Breaking Changes。
   - **數字/事實一致**:文件裡的「N 個注入點 / N tests / migration 編號 / 欄位」等具體數字是否與現況相符(常見過時點)。

4. **回報**
   - 先給一句結論:`✅ 同步` 或 `⚠️ N 處落差`。
   - 表格列每個落差:`code 改動` → `應反映於哪個文件` → `建議補寫內容`。
   - 列出過時(stale)描述。
   - **不要自動改文件**;除非使用者說「幫我補上」,才依建議編輯,並維持 frontmatter / 連結正確、不引入未追蹤檔(如 TKT)。

## Output 範例

```
⚠️ 3 處落差(branch feat/x vs origin/dev)

| code 改動 | 應反映於 | 建議 |
|---|---|---|
| apis/foo.py 新增 bar() | <sha>.md Changes Summary / DESIGN | 補「新增 bar 端點 + 注入」一行 |
| sql/migrations/014__… | <sha>.md New Files | 列入並標 migration 編號 |
| 移除 legacy_check()(break) | changelog Breaking Changes | 補一條 |

Stale:feature doc 仍寫「6 個注入點」,實際 7。
```

## Notes
- 純函數/格式/註解微調可不必逐一入文件;聚焦「新增/刪除檔、架構決策、公開介面、schema、break 行為」(對齊 docs-management 的 feature-doc 觸發條件)。
- 此 skill 只檢查 + 建議;實際補寫沿用 `docs-management` 規則。
