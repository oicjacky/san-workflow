---
name: diagnosing-bugs
description: "Diagnosis loop for hard bugs and performance regressions. Use when the user says \"diagnose\"/\"debug this\", or reports something broken/throwing/failing/slow."
origin: "mattpocock/skills — skills/engineering/diagnosing-bugs @ 1.2.3 (8b78b531), MIT © 2026 Matt Pocock"
adapted: "「定位」段、「影響範圍」段（2026-10-09 新增）、Phase 5、Phase 6 為在地改寫（接 docs-management／tdd-methodology 基質）；Phase 1–4 與 Redact 段與上游逐字一致"
---

# Diagnosing Bugs

A discipline for hard bugs. Skip phases only when explicitly justified.

When exploring the codebase, read `docs/CONTEXT.md` (if it exists) to get the project's domain vocabulary, and check the 「拍板記錄／決策紀錄」sections of `docs/feat/<slug>/DESIGN.md` in the area you're touching.

## 定位

本 skill 是 pipeline 的**前置分支**，不是新的一段：

```
新功能:  Research → Plan → TDD → Code Review → Commit
壞掉了:  diagnose(P1–P4) → 影響範圍 ↗
```

Phase 1–4 跑完拿到根因、再量化影響範圍（見下方「影響範圍」段）後，**收斂回 TDD 那一段**（`tdd-methodology` 的 RED→GREEN），之後 Code Review → Commit 完全照 `rules/workflow.md` 的常規流程。

`rules/workflow.md` 的 Research 段（WebSearch 找現有方案）**不適用於本流程**——在 debug 情境，紅燈迴路建好之前就讀碼推理原因、或上網找解法，正是 Phase 1 存在要防的失敗；為了建迴路而讀碼不在此限。

## Redact

This skill has you show commands, outputs and captured artifacts. **Redact every secret first** — write `<REDACTED>` in its place. Build loops against env vars, so the credential stays in the environment rather than in what you show. Captured artifacts carry auth headers: quote only the lines that carry the signal.

If the redacted output is not enough to diagnose the bug, say so and ask the user.

## Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a **tight** pass/fail signal for the bug — one that goes red on _this_ bug — you will find the cause; bisection, hypothesis-testing, and instrumentation all just consume it. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

### Ways to construct one — try them in roughly this order

1. **Failing test** at whatever seam reaches the bug — unit, integration, e2e.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) — drives the UI, asserts on DOM/console/network.
5. **Replay a captured trace.** Save a real network request / payload / event log to disk; replay it through the code path in isolation.
6. **Throwaway harness.** Spin up a minimal subset of the system (one service, mocked deps) that exercises the bug code path with a single function call.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit, dataset, version), automate "boot at state X, check, repeat" so you can `git bisect run` it.
9. **Differential loop.** Run the same input through old-version vs new-version (or two configs) and diff outputs.
10. **HITL bash script.** Last resort. If a human must click, drive _them_ with `scripts/hitl-loop.template.sh` so the loop is still structured. Captured output feeds back to you.

Build the right feedback loop, and the bug is 90% fixed.

### Tighten the loop

Treat the loop as a product. Once you have _a_ loop, **tighten** it:

- Can I make it faster? (Cache setup, skip unrelated init, narrow the test scope.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

A 30-second flaky loop is barely better than no loop; a 2-second deterministic one is tight — a debugging superpower.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop the trigger 100×, parallelise, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; 1% is not — keep raising the rate until it's debuggable.

### When you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Ask the user for: (a) access to whatever environment reproduces it, (b) a redacted captured artifact (HAR file, log dump, core dump, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Do **not** proceed to hypothesise without a loop.

### Completion criterion — a tight loop that goes red

Phase 1 is done when the loop is **tight** and **red-capable**: you can name **one command** — a script path, a test invocation, a curl — that you have **already run at least once** (show the invocation and its output, redacted), and that is:

- [ ] **Red-capable** — it drives the actual bug code path and asserts the **user's exact symptom**, so it can go red on this bug and green once fixed. Not "runs without erroring" — it must be able to _catch this specific bug_.
- [ ] **Deterministic** — same verdict every run (flaky bugs: a pinned, high reproduction rate, per above).
- [ ] **Fast** — seconds, not minutes.
- [ ] **Agent-runnable** — you can run it unattended; a human in the loop only via `scripts/hitl-loop.template.sh`.

If you catch yourself reading code to build a theory before this command exists, **stop — jumping straight to a hypothesis is the exact failure this skill prevents.** No red-capable command, no Phase 2.

## Phase 2 — Reproduce + minimise

Run the loop. Watch it go red — the bug appears.

Confirm:

- [ ] The loop produces the failure mode the **user** described — not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] The failure is reproducible across multiple runs (or, for non-deterministic bugs, reproducible at a high enough rate to debug against).
- [ ] You have captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually addresses it.

### Minimise

Once it's red, shrink the repro to the **smallest scenario that still goes red**. Cut inputs, callers, config, data, and steps **one at a time**, re-running the loop after each cut — keep only what's load-bearing for the failure.

Why bother: a minimal repro shrinks the hypothesis space in Phase 3 (fewer moving parts left to suspect) and becomes the clean regression test in Phase 5.

Done when **every remaining element is load-bearing** — removing any one of them makes the loop go green.

Do not proceed until you have reproduced **and** minimised.

## Phase 3 — Hypothesise

Generate **3–5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe — discard or sharpen it.

**Show the ranked list to the user before testing.** They often have domain knowledge that re-ranks instantly ("we just deployed a change to #3"), or know hypotheses they've already ruled out. Cheap checkpoint, big time saver. Don't block on it — proceed with your ranking if the user is AFK.

## Phase 4 — Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger / REPL inspection** if the env supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

**Perf branch.** For performance regressions, logs are usually wrong. Instead: establish a baseline measurement (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.

## 影響範圍（在地新增）

根因確認後、動手修之前，用唯讀的方式量化影響範圍：受影響的筆數、時間區間、對象（使用者、租戶、批次等），先向使用者報告再修。這些數字決定修完要不要補資料、要通知誰。

- 只用唯讀方式：查詢、log、既有報表；不為了量化去改資料或重跑任務。
- 缺存取權限（例如 DB 要先開 VPN）時，說明缺哪種權限、由誰提供，不要自己繞過。

## Phase 5 — Fix + regression test（委派）

診斷到此結束。修復與回歸測試**交由 `tdd-methodology` 的 RED→GREEN 迴圈**——seam 的事先確認、一次一片、好測試的判準都在那裡定義，本 skill 不重複。

移交時帶三樣東西給 TDD 段：**最小化後的重現情境**、**Phase 1 的紅燈指令**、**驗證為真的那條假說**。

本 skill 保留兩條 TDD 不涵蓋的判準：

> **回歸測試必須先被看著紅過一次，而且要紅在這個 bug 上。**
>
> `tdd-methodology` 的「Red before green」要求先寫失敗測試；debug 情境要求更嚴——
> 上游原文把 `Watch it fail` / `Watch it pass` 列為獨立步驟就是為此。套用 fix 之前先跑一次、
> **親眼看到它紅**，確認它紅的原因是這個 bug（而非匯入錯誤、fixture 壞掉、斷言寫在別的行為上）。
> 沒看過紅的測試，變綠不能證明任何事。這與 Phase 1 的 red-capable 判準是同一條標準。


> **沒有正確的 seam，就不要硬寫回歸測試——這件事本身就是發現。**
>
> 正確的 seam 是「測試以 bug 在 call site 實際發生的樣態去驅動它」。若唯一可用的 seam 太淺（bug 需要多個 caller 才會出現，卻只能寫單 caller 測試；或單元測試無法重現觸發 bug 的呼叫鏈），在那裡寫回歸測試只會給出假的信心。
>
> 遇到這種情況：**記下來**。這代表 codebase 的結構讓這個 bug 鎖不住。依 Phase 6 開 `TKT-*` 追蹤。

修完後，**回頭跑 Phase 1 的迴圈對原始（未最小化）情境**，確認真的綠了。

## Phase 6 — Cleanup + post-mortem

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or absence of seam is documented)
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` the prefix)
- [ ] Throwaway prototypes deleted (or moved to a clearly-marked debug location)
- [ ] The hypothesis that turned out correct is stated in the commit / PR message — so the next debugger learns

### 落檔（依 `docs-management`）

- **建 `ISS-<YYYYMMDD>-<slug>.md`**，把**驗證為真的那條假說**填進 **Root Cause** 欄位，症狀與 Phase 1 的紅燈指令填進重現步驟。修復後更新 `status: fixed` 與 `fixed-by`。

**Then ask: what would have prevented this bug?**

若答案牽涉架構改動（沒有好的測試 seam、caller 糾纏、隱性耦合），**開 `TKT-*` 追蹤該架構問題**（依 `docs-management`，放對應 feature 資料夾或 `_general/`），把具體症狀寫進去。設計語彙用 `codebase-design`（seam 該放哪、deletion test、一個 adapter 是假 seam）。

這個建議要在**修好之後**才提——此刻你掌握的資訊比開始時多。
