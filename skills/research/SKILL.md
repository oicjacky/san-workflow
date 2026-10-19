---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
origin: "mattpocock/skills — skills/engineering/research @ 1.2.3 (8b78b531), MIT © 2026 Matt Pocock"
adapted: "「落檔」段改寫為一律委派 docs-management（上游原文允許 match existing convention）；開頭改為依調查規模決定是否開 background agent（2026-10-09）；第 1、2 點與上游逐字一致"
---

# Research

When the research needs more than a handful of lookups (several sources, long docs), spin up a **background agent** so you keep working while it reads; for a single fact or one page, look it up directly.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.

## 落檔（委派 `docs-management`）

**本 skill 不自帶任何命名或路徑規則。** 落檔一律依 `docs-management` §「建立 Research 報告」——
命名、frontmatter、`related` 雙向連結、`status` 生命週期（`in-progress` → `complete` → `superseded`）
都在那裡定義，且那裡已經接上 per-repo 覆寫鏈（該 repo 的 `docs/docs-as-code.md`，若無則 `CLAUDE.md`，
再退回 baseline）。

不在此處複述規則，是因為「一件事只有一個 owner」——上游原文的「match the existing convention」
在有多套慣例的 repo 裡會拿到互斥的答案，而該由誰仲裁，`docs-management` 已經有答案了。

兩件呼應之處，不是新規則、只是說明為何委派得起來：

- 上游要求「follow every claim back to the source that owns it」，與 `docs-management` 的
  「**逐節標一手來源**，不引用二手轉述」實質同構。
- 上游要求 findings 可據以行動，與 `docs-management` 的「明確寫出建議採用／不採用 X，因為 Y，
  並在 `related` 連到後續的 `TKT-*`」一致。
