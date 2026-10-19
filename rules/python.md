---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python

## Environment
- Use `uv` for virtual environment and dependency management
- Ensure venv is active before execution (`uv run` or `.venv/bin/python`)
- Use `uvx` for global tools (e.g., `uvx bandit`, `uvx pip-audit`)
- Use `uv sync --frozen` for reproducible dependency installs

## Standards
- PEP 8 naming; type annotations required on all function/method signatures
- ruff for linting and formatting
- Flag print() in src/ — use logging module instead

## Idioms
- **EAFP over LBYL** — prefer `try/except` to pre-condition checks (avoids races).
- **Exceptions**: catch specific types, never bare `except:`; chain with `raise NewError(...) from e`. Define a per-app base (`AppError`) and subclass (e.g. a FastAPI `AppError(status_code=...)` hierarchy).
- **No mutable default args** (use `None` + `x = x or []`); **no `from module import *`**.
- **Comprehensions** for simple map/filter only; if it needs ≥2 conditions or a transform, write a generator function. Use generator *expressions* in `sum()/any()/…`, not throwaway lists.
- **`yield` / generators** for large or streamed data (read files line-by-line, not `.read()`).
- **`"".join(...)`** to build strings in a loop — never `+=` (O(n²)).
- **`@dataclass`** for plain entities; **Pydantic** when validation/serialisation is needed; **`NamedTuple`** for small immutable values.
- **`Protocol`** for structural/duck typing over ABCs.
- **`__slots__`** on hot-path / high-count classes to cut memory.
- **Concurrency**: threads or `async`/`httpx` for I/O-bound; `ProcessPoolExecutor` for CPU-bound (never thread CPU work — GIL).
- **`with`** for every resource; `@contextmanager` for ad-hoc setup/teardown.
- **Imports**: stdlib → third-party → local (ruff sorts); expose package API via `__all__`.

## Hooks
- Recommended: a PostToolUse hook that runs an **advisory** `ruff check` + `ruff format --diff` on `.py` edits — it reports findings to the agent and **never rewrites**. Only act in projects with a ruff config (each project's own rules apply); skip the rest.

## Reference Skills
- `python-testing` — fixtures, mocking, parametrization, async tests
- `python-quality-gates` — test layout, coverage gate, CI wiring, pre-PR checklist
- `tdd-methodology` — what makes a good test, seams, anti-patterns
- `/security-review` — OWASP / secrets / dependency audit（內建 skill）
- Language idioms are inline above (§ Idioms).
