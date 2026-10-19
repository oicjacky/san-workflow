---
name: tdd-methodology
description: "Test-driven development methodology: what makes a test worth keeping, where the seam is, the red→green loop rules, test anti-patterns, and when to mock. Use when building features or fixing bugs test-first, or when a test's design (not its syntax) is in question. Python mechanics see `python-testing`; layout/coverage/CI gates see `python-quality-gates`."
origin: "mattpocock/skills — skills/engineering/tdd @ 1.2.0 (ed37663c), MIT © 2026 Matt Pocock"
adapted: "「分層」段、開頭路徑（CONTEXT.md→docs/CONTEXT.md、ADRs→DESIGN.md 拍板記錄）、§Seams 指向 codebase-design 的註記為在地改寫；其餘與上游逐字一致"
---

# Test-Driven Development

TDD is the red → green loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle — consult them before and during the loop, not after.

When exploring the codebase, read `docs/CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect the 「拍板記錄／決策紀錄」sections of `docs/feat/<slug>/DESIGN.md` in the area you're touching.

## 分層

本 skill 只管**判斷**——測什麼、怎樣算好測試。它不綁語言、不定義覆蓋率數字。

| 階段 | 負責 |
|------|------|
| **判斷** — 好測試的定義、seam 位置、反模式、該不該 mock | **本 skill** |
| **撰寫** — pytest fixtures、AsyncMock、autospec、FastAPI dependency overrides | `python-testing` |
| **驗收** — 目錄結構、pyproject/CI 設定、80% 覆蓋率閘門、Pre-PR 檢查表 | `python-quality-gates` |

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists — and survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams — where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

> 本 skill 只管「測試站在 seam 上」。**seam 該放哪**是設計決策，見 `codebase-design`
> （deep module、deletion test、「一個 adapter 是假 seam，兩個才是真 seam」）。
> 註：`codebase-design` 用 Feathers 原義定義 seam（可替換行為的位置），與此處的操作性定義
> 是同一概念的兩面，刻意不統一。

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test and confirm them with the user. No test is written at an unconfirmed seam. You can't test everything — agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological** — the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth — a known-good literal, a worked example, the spec.
- **Horizontal slicing** — writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead — one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see `rules/workflow.md` § Pipeline — Code Review 含 Refactor), not the red → green implementation cycle.
