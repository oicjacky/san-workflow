---
name: python-testing
description: "Use when writing or modifying Python tests: pytest fixtures, mocking, parametrization, async tests, FastAPI dependency overrides, coverage design."
origin: ECC
---

# Python Testing Patterns

Project-specific pytest patterns and conventions for Python codebases.

This skill owns the **撰寫層 (pattern layer)** only — the mechanics of writing a Python test once you have decided what to test.

- **判斷層** — what makes a good test, where the seam is, test anti-patterns, and **whether** to mock at all: see `tdd-methodology` (language-neutral; includes the RED → GREEN loop).
- **驗收層** — directory layout, pytest/coverage config, the 80% gate (canonical; not redefined here), and the Pre-PR checklist: see `python-quality-gates`.

## When to Activate

- Writing or modifying Python tests
- Designing test suites for Python projects
- Setting up testing infrastructure (conftest, pytest config)
- Reviewing Python test coverage design

## Conftest Organization

Shared fixtures live in `tests/conftest.py`. Project convention for FastAPI apps: use `ASGITransport` — do not spin up a real server.

```python
# tests/conftest.py
import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app

@pytest.fixture
async def client():
    """Async test client for FastAPI."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest.fixture
async def auth_headers(client: AsyncClient):
    """Generate auth headers for API testing."""
    response = await client.post("/api/login", json={
        "username": "test", "password": "test"
    })
    token = response.json()["token"]
    return {"Authorization": f"Bearer {token}"}
```

Conventions:

- Directory layout: see `python-quality-gates` § Test File Organization (`tests/unit/`, `tests/integration/`, `tests/e2e/`).
- Fixtures used by a single module stay in that module; promote to `conftest.py` only when shared.
- Use `scope="session"` only for genuinely expensive, immutable resources; mutable state must stay function-scoped to preserve test isolation.
- Global-state resets go in an `autouse` fixture in `conftest.py`:

```python
@pytest.fixture(autouse=True)
def reset_config():
    """Automatically runs before every test."""
    Config.reset()
    yield
    Config.cleanup()
```

## FastAPI Test Patterns

### Dependency Overrides

Override FastAPI dependencies instead of patching internals — this tests the real wiring:

```python
from app.main import app
from app.api.deps import get_conn, get_current_user

# Override in test setup
app.dependency_overrides[get_conn] = lambda: fake_conn
app.dependency_overrides[get_current_user] = lambda: test_user

# ALWAYS clean up after tests (fixture teardown or finally-block)
app.dependency_overrides.clear()
```

Pitfall: forgetting `dependency_overrides.clear()` leaks the override into unrelated tests. Wrap it in a yield-fixture so cleanup is guaranteed.

### Endpoint Tests via the Shared Client Fixture

```python
@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    response = await client.post("/api/users", json={
        "name": "Alice", "email": "alice@example.com"
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Alice"
```

## Async Testing Pitfalls

- Every async test needs `@pytest.mark.asyncio` (or `asyncio_mode = "auto"` in config); a missing marker makes the test silently pass without running the coroutine.
- Async fixtures require pytest-asyncio; a plain `@pytest.fixture` returning a coroutine hands the test an un-awaited coroutine object.
- Mock async callables with `AsyncMock` (or `@patch` on an async target, which auto-selects it) — a plain `Mock` returns a non-awaitable and fails at the `await` site:

```python
@pytest.mark.asyncio
@patch("mypackage.async_api_call")  # async target → AsyncMock automatically
async def test_async_mock(api_call_mock):
    api_call_mock.return_value = {"status": "ok"}

    result = await my_async_function()

    api_call_mock.assert_awaited_once()  # not assert_called_once for awaits
    assert result["status"] == "ok"
```

## Mocking Patterns

> **判斷層邊界**:**該不該** mock 由 `tdd-methodology`(§ mocking.md)決定——只在系統邊界 mock(外部 API、時間、隨機、DB/檔案系統視情況),不 mock 自己的類別與內部協作者。本節只管「已決定要 mock 之後怎麼寫」。
> 同理,`assert_called_once` / `assert_awaited_once` 這類**呼叫次數斷言僅適用於邊界 mock 的驗證**;對內部協作者使用即是 `tdd-methodology` 明列的反模式(implementation-coupled test)。

Prefer FastAPI dependency overrides (above) at API boundaries; use `patch` for genuine system boundaries that are not injected.

### Autospec — Catch API Misuse

```python
@patch("mypackage.DBConnection", autospec=True)
def test_autospec(db_mock):
    db = db_mock.return_value
    db.query("SELECT * FROM users")
    # Fails if DBConnection has no query method — plain Mock would not
    db_mock.assert_called_once()
```

Default to `autospec=True` when patching classes; it turns signature drift into test failures instead of false greens.

### Simulating Failures with side_effect

```python
@patch("mypackage.api_call")
def test_api_error_handling(api_call_mock):
    api_call_mock.side_effect = ConnectionError("Network error")

    with pytest.raises(ConnectionError):
        api_call()
```

### Mocking open() / Context Managers

```python
from unittest.mock import patch, mock_open

@patch("builtins.open", new_callable=mock_open)
def test_file_reading(mock_file):
    mock_file.return_value.read.return_value = "file content"

    result = read_file("test.txt")

    mock_file.assert_called_once_with("test.txt", "r")
    assert result == "file content"
```

For real file I/O prefer pytest's `tmp_path` fixture over `tempfile` — automatic cleanup, no try/finally:

```python
def test_with_tmp_path(tmp_path):
    test_file = tmp_path / "test.txt"
    test_file.write_text("hello world")
    assert process_file(str(test_file)) == "hello world"
```

### Mocking Properties

Properties cannot be set as plain attributes on a Mock — use `PropertyMock` on the type:

```python
from unittest.mock import Mock, PropertyMock

@pytest.fixture
def mock_config():
    config = Mock()
    type(config).debug = PropertyMock(return_value=True)
    type(config).api_key = PropertyMock(return_value="test-key")
    return config
```

## Parametrization Conventions

- Always add `ids=` when the parameter values are not self-explanatory — failure output becomes readable:

```python
@pytest.mark.parametrize("input,expected", [
    ("valid@email.com", True),
    ("invalid", False),
    ("@no-domain.com", False),
], ids=["valid-email", "missing-at", "missing-domain"])
def test_email_validation(input, expected):
    assert is_valid_email(input) is expected
```

- Use parametrized fixtures (not parametrized tests) when the whole suite should run against multiple backends:

```python
@pytest.fixture(params=["sqlite", "postgresql"])
def db(request):
    if request.param == "sqlite":
        return Database(":memory:")
    return Database("postgresql://localhost/test")
```

## Database Test Pattern

Give every test run a fresh, throwaway test database (a reused one accumulates dirty data and produces false passes). Inside it, isolate each test in a rolled-back nested transaction rather than re-creating the schema per test:

```python
@pytest.fixture
def db_session():
    """Test session — everything rolls back after each test."""
    session = Session(bind=engine)
    session.begin_nested()
    yield session
    session.rollback()
    session.close()
```

## Security Test Patterns

When the agreed seams include a protected endpoint, the 401 and 403 assertions below are required; add the 422 and 429 ones as that seam needs:

```python
@pytest.mark.asyncio
async def test_requires_authentication(client: AsyncClient):
    response = await client.get("/api/protected")
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_requires_admin_role(client: AsyncClient, user_token: str):
    response = await client.get(
        "/api/admin",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_rejects_invalid_input(client: AsyncClient):
    response = await client.post("/api/users", json={"email": "not-an-email"})
    assert response.status_code == 422

@pytest.mark.asyncio
async def test_enforces_rate_limits(client: AsyncClient):
    responses = [await client.get("/api/endpoint") for _ in range(101)]
    assert any(r.status_code == 429 for r in responses)
```

> For a full security review, run the built-in `/security-review` skill.

## Markers and Test Selection

Register markers in `pyproject.toml` (`--strict-markers` makes unregistered markers an error). Convention: `unit`, `integration`, `slow`.

```bash
pytest -m "not slow"          # skip slow tests during development
pytest -m "unit and not slow" # fast unit loop
pytest --lf                   # re-run last failures
pytest -k "test_user"         # pattern match
```

## pytest Configuration

Project convention: configure in `pyproject.toml`, not `pytest.ini`.

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-fail-under=80",   # gate defined in python-quality-gates
]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

## Quick Reference

| Pattern | Usage |
|---------|-------|
| `app.dependency_overrides[dep] = ...` | Override FastAPI dependencies (remember to clear) |
| `@patch(..., autospec=True)` | Mock that fails on signature drift |
| `AsyncMock` / `assert_awaited_once()` | Mock and verify async callables |
| `side_effect = SomeError(...)` | Simulate failures |
| `mock_open` | Mock `open()` context manager |
| `PropertyMock` | Mock properties via `type(mock).attr` |
| `parametrize(..., ids=[...])` | Readable parametrized failure output |
| `tmp_path` fixture | Temp files with automatic cleanup |
| `begin_nested()` + rollback fixture | Per-test DB isolation |

## Cross-References

| Need | Skill |
|------|-------|
| TDD methodology (good tests, seams, anti-patterns) | `tdd-methodology` |
| 80%+ coverage gate, CI wiring, pre-PR checklist | `python-quality-gates` |
| Test directory layout | `python-quality-gates` § Test File Organization |
| Python idioms, decorators, generators | `rules/python.md` (§ Idioms) |
| Security review | `/security-review`（內建） |
| Tooling (ruff, pyright) | `rules/python.md` |
