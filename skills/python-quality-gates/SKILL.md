---
name: python-quality-gates
description: "Python test layout, pytest/coverage configuration, the 80% coverage gate, pre-commit/CI wiring, and the Pre-PR verification checklist (lint/types/tests/security/diff). For TDD methodology see `tdd-methodology`; for pytest patterns see `python-testing`."
origin: ECC
---

# Python Quality Gates

This skill owns the **execution and gate layer** of testing: where tests live, how pytest and coverage are configured, and what must pass before a PR ships.

It deliberately owns **no methodology**. Three stages, three owners:

| Stage | Owner | Scope |
|-------|-------|-------|
| **判斷** — what makes a good test, where the seam is, anti-patterns, whether to mock | `tdd-methodology` | language-neutral |
| **撰寫** — fixtures, mocking mechanics, parametrize, async tests, FastAPI overrides | `python-testing` | Python |
| **驗收** — layout, config, coverage gate, CI, Pre-PR checklist | **this skill** | Python |

> RED → GREEN 迴圈、seam 確認、切片方式、refactor 時機一律歸 `tdd-methodology`,本 skill 不重複定義。

## When to Activate

- Setting up or changing a Python project's test layout, pytest/coverage config, or CI gate
- Verifying a change is ready for PR
- Answering "what is the coverage requirement" / "where do tests go"

## Coverage Requirements (canonical definition)

This section is the single source of truth for coverage; other skills reference it and must not redefine it.

- Minimum **80% coverage** (unit + integration + E2E combined)
- Which edge cases get tests is decided at the agreed seams (`tdd-methodology`)
- Error scenarios tested
- Boundary conditions verified

Verify with:

```bash
python3 -m pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

## Test Types

| Type | Scope | Tooling |
|------|-------|---------|
| Unit | Individual functions, service/model logic, pure functions, helpers | pytest |
| Integration | API endpoints, database operations, service interactions, external API calls | pytest + httpx.AsyncClient |
| E2E | Critical user flows, complete workflows, browser automation | playwright-python / httpx.AsyncClient |

## Test File Organization

```
project/
├── src/
│   ├── models/
│   ├── services/
│   ├── api/routers/
│   └── main.py
├── tests/
│   ├── conftest.py                # Shared fixtures
│   ├── unit/
│   │   ├── test_models.py
│   │   └── test_services.py
│   ├── integration/
│   │   └── test_api_markets.py    # FastAPI + httpx tests
│   └── e2e/
│       └── test_market_flow.py    # playwright-python tests
└── pyproject.toml
```

## Coverage Enforcement

```toml
# pyproject.toml
[tool.pytest.ini_options]
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-fail-under=80",
]

[tool.coverage.run]
branch = true

[tool.coverage.report]
fail_under = 80
show_missing = true
```

## Continuous Testing

```bash
# Watch mode during development (pytest-watch)
ptw -- --cov=src

# Pre-commit: ruff (lint + format) + pytest
# See: https://github.com/astral-sh/ruff-pre-commit
pre-commit run --all-files
```

```yaml
# CI (GitHub Actions) — minimum gate
- run: uv sync --frozen
- run: ruff check .
- run: uvx pyright .
- run: python3 -m pytest --cov=src --cov-report=xml
```

---

## Pre-PR Verification Checklist

Run these phases before creating a PR:

| Phase | Command | Action on Fail |
|-------|---------|----------------|
| **Lint** | `ruff check . && ruff format --check .` | STOP, fix first |
| **Types** | `uvx pyright .` | Fix critical errors |
| **Tests** | `python3 -m pytest --cov=src --cov-fail-under=80` | Must pass, 80%+ coverage |
| **Security** | grep for secrets, `print()` in src/ | Remove before PR |
| **Diff** | `git diff --stat` | Review unintended changes |

Produce a brief report: Lint/Types/Tests/Security — PASS or FAIL, then Overall: READY / NOT READY for PR.
