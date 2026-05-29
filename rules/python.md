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

## Hooks
- PostToolUse: ruff auto-format, pyright type check

## Reference Skills
- `skills/python-backend` — FastAPI, Pydantic v2, async patterns, LLM integration
- `skills/python-patterns` — idioms, decorators, concurrency
- `skills/python-testing` — fixtures, mocking, parametrization
- `skills/security-review` — OWASP checklists
