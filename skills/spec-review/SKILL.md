---
name: spec-review
description: "Review 的 Spec 軸：比對本分支的程式碼改動與該 feature 的規格文件（DESIGN.md / feature doc / TKT-*），找出漏做、超做（scope creep）、做錯。發 MR 前或使用者說「有沒有照規格做」「做的跟講的一樣嗎」「檢查 scope creep」時使用。只讀+回報，不自動改動。"
origin: "衍生自 mattpocock/skills — skills/engineering/code-review @ 1.2.0 (ed37663c) 的 Spec 軸，MIT © 2026 Matt Pocock"
adapted: "僅取上游的 Spec 軸並改接 docs/feat/<slug>/ 基質；Standards 軸未納入（與內建 /code-review 重疊）"
---

# Spec Review

回答一個問題：**做出來的東西，跟當初說要做的東西，是同一件事嗎？**

這是 review 的第三軸。三軸刻意分開，因為一個改動可以在某一軸全過、在另一軸全砸：

| 軸 | 問的問題 | 由誰做 |
|---|---|---|
| 品質與正確性 | 這段程式碼寫得對嗎？ | 內建 `/code-review` |
| 安全 | 有沒有可被利用的漏洞？ | 內建 `/security-review` |
| **Spec** | **做的是不是當初要的那件事？** | **本 skill** |

分軸的用意是**不讓一軸掩蓋另一軸**：完全符合規範但實作了錯的東西 = 品質過、Spec 砸；完全照票做但寫得很糟 = Spec 過、品質砸。因此本 skill 的發現**不與其他兩軸合併排序**。

方向上與 `mr-docs-sync` 互補、**不重疊**：

- `mr-docs-sync`：**code → docs**，改了東西但文件沒跟上。
- 本 skill：**docs → code**，文件說要做的東西沒做／做過頭／做錯。

## Steps

### 1. 定位 base 與 diff

- base 分支依 repo 而定（`origin/dev` / `origin/main` / `origin/master`）；可由
  `git rev-parse --abbrev-ref --symbolic-full-name @{u}` 或常見命名推定，不確定就問使用者。
- 程式碼改動：`git diff <base>...HEAD --stat -- ':!docs/'`
- commit 清單：`git log <base>..HEAD --oneline`
- **務必三點（`...`）而非兩點**：分支若落後 base，兩點 `git diff <base> HEAD` 會把「base 領先你」
  也算成你的改動 → 假性落差。三點以 merge-base 為基準，只反映本分支引入的改動。
- 動手前先確認 base ref 解得開（`git rev-parse <base>`）且 diff 非空。ref 錯或 diff 空要在這裡失敗，
  不要帶著壞輸入往下走。

### 2. 找到規格來源

依序找，找到就停：

1. 使用者直接給的路徑。
2. **由分支名 → slug，對應 `docs/feat/<slug>/`**（與 `mr-docs-sync` 同一套定位）。該資料夾內：
   - `DESIGN.md` — 架構決策、目標／非目標、**「拍板記錄」「決策紀錄」段落**。這是最主要的規格來源。
   - `ANALYSIS.md` — 現況盤點；用來判斷「這個改動是不是在解當初盤點出的問題」。
   - `TKT-*.md` — 逐項待辦，最適合逐條核對「做了沒」。
   - `<6hex>.md`（feature doc）— as-built 描述；注意它是**結果**不是**規格**，用來比對時要留意雞生蛋問題。
3. 不屬於特定 feature 的：`docs/feat/_general/` 下對應的 `TKT-*` / `ISS-*`。
4. commit message 裡的 issue / MR 參照（`#123`、`!67`）——GitHub 用 `gh issue view <N>` /
   `gh pr view <N>`，GitLab 用 `glab issue view <N>` / `glab mr view <N>` 取回內容。
   若 CLI 未認證或該 repo 無遠端 issue tracker，**不要猜**，直接走第 5 項。
5. 都找不到 → **問使用者規格在哪**。若使用者說沒有規格，直接回報「no spec available」並結束——
   **不要拿自己的想像當規格來評判**。

先讀該 repo 的 `docs/docs-as-code.md`（若無則 `CLAUDE.md`）確認實際追蹤規則（例如某些 repo 不追蹤
`TKT-*`）。追蹤集合不同會影響哪些檔案算數。

### 3. 逐項對照（spec → code）

三類發現，**每一條都要引用規格原文**（檔名 + 該行／該段），否則就是臆測：

- **(a) 漏做／只做一半** — 規格要求的東西在 diff 裡找不到，或只實作了部分條件。
  `DESIGN.md` 的「拍板記錄」「決策紀錄」是最容易漏的地方——拍板了但沒進 code。
- **(b) 超做（scope creep）** — diff 裡有規格沒要求的行為。特別注意 `DESIGN.md` 的
  **「不在 scope 內」** 段落：明文排除卻做了，是最嚴重的一種。
- **(c) 做錯** — 看起來實作了，但實作方式與規格描述不符（順序、預設值、邊界條件、錯誤處理、
  選了被否決的那個方案）。

判斷輔助：

- 規格若列了**選項比較表**並標了選定方案，確認 code 走的是選定的那條，不是被否決的。
- 規格若有**開放議題**且標示未拍板，該部分不算落差——標為「規格未定，實作先行」請使用者確認。
- 規格本身若過時（`DESIGN.md` 寫的是舊設計，後來口頭改了），這是**發現**不是錯誤：回報
  「code 與 spec 不符，但看起來是 spec 過時」，請使用者裁決哪邊才對。

### 4. 回報

- 先給一句結論：`✅ 符合規格` 或 `⚠️ N 處落差`。
- 表格逐條列出：

| 類型 | 規格原文（檔案:段落） | diff 現況 | 建議 |
|---|---|---|---|
| 漏做 | `DESIGN.md` 拍板記錄 D3「失敗要重試三次」 | `client.py` 只 try 一次 | 補 retry，或請使用者確認 D3 是否已作廢 |
| 超做 | `DESIGN.md`「不在 scope 內：不刪 inline path」 | `tasks.py` 刪了 `_inline_parse()` | 確認是否刻意擴大 scope；是的話補進 DESIGN |
| 做錯 | `TKT-004` 「以 `account_id` 對應」 | 實際用 `user_id` | 修正或說明為何改 |

- 規格未定而實作先行的，另立一段列出，請使用者拍板。
- **不要自動改程式碼或文件**；除非使用者明說要改。
- 結尾先標出本軸最嚴重的一項，完整清單照列，**不與 `/code-review`、`/security-review` 的發現合併排序**。

## Notes

- 純重構／格式／註解調整不必逐條對規格；聚焦「新增或移除的行為、公開介面、schema、預設值、
  break 行為」——與 `docs-management` 的 feature-doc 觸發條件對齊。
- 找不到規格時的正確行為是**停下來問**，不是降級成品質 review——那是內建 `/code-review` 的工作。
