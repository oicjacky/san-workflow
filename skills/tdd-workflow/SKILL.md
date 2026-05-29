---
name: tdd-workflow
description: Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.
---

# Test-Driven Development Workflow

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## When to Activate

- Writing new features or functionality
- Fixing bugs or issues
- Refactoring existing code
- Adding API endpoints
- Creating new modules or classes

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

#### Unit Tests
- Individual functions and utilities
- Service/model logic
- Pure functions
- Helpers and utilities

#### Integration Tests
- API endpoints
- Database operations
- Service interactions
- External API calls

#### E2E Tests (playwright-python / httpx.AsyncClient)
- Critical user flows
- Complete workflows
- Browser automation
- API flow tests

## TDD Workflow Steps

### Step 1: Write User Journeys
```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### Step 2: Generate Test Cases
For each user journey, create comprehensive test cases:

```python
@pytest.mark.asyncio
async def test_search_returns_relevant_markets(client: AsyncClient): ...

@pytest.mark.asyncio
async def test_search_handles_empty_query(client: AsyncClient): ...

@pytest.mark.asyncio
async def test_search_falls_back_when_redis_unavailable(client: AsyncClient, monkeypatch): ...

@pytest.mark.asyncio
async def test_search_sorts_by_similarity(client: AsyncClient): ...
```

### Step 3: Run Tests (They Should Fail)
```bash
python3 -m pytest
# Tests should fail - we haven't implemented yet
```

### Step 4: Implement Code
Write minimal code to make tests pass:

```python
async def search_markets(query: str) -> list[MarketResult]:
    """Search markets by semantic similarity."""
    ...
```

### Step 5: Run Tests Again
```bash
python3 -m pytest
# Tests should now pass
```

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

### Step 7: Verify Coverage
```bash
python3 -m pytest --cov=src --cov-report=term-missing --cov-fail-under=80
# Verify 80%+ coverage achieved
```

## Testing Patterns

### Unit Test Pattern (pytest)
```python
import pytest
from src.services.market import MarketService
from src.models import Market


class TestMarketService:
    def test_create_market(self, market_service: MarketService):
        market = market_service.create(name="Test", description="A test market")
        assert market.name == "Test"
        assert market.id is not None

    def test_create_market_validates_name(self, market_service: MarketService):
        with pytest.raises(ValueError, match="Name cannot be empty"):
            market_service.create(name="", description="desc")

    def test_create_market_rejects_duplicate(self, market_service: MarketService):
        market_service.create(name="Existing", description="desc")
        with pytest.raises(DuplicateError):
            market_service.create(name="Existing", description="desc")

    def test_list_markets_empty(self, market_service: MarketService):
        result = market_service.list_all()
        assert result == []
```

### API Integration Test Pattern (FastAPI + httpx)
```python
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_markets_returns_list(client: AsyncClient):
    response = await client.get("/api/markets")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert isinstance(data["data"], list)


@pytest.mark.asyncio
async def test_get_markets_validates_params(client: AsyncClient):
    response = await client.get("/api/markets?limit=invalid")
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_markets_handles_db_error(client: AsyncClient, monkeypatch):
    async def raise_error(*args, **kwargs):
        raise RuntimeError("DB connection failed")

    monkeypatch.setattr("src.db.session.execute", raise_error)
    response = await client.get("/api/markets")
    assert response.status_code == 500
    assert "error" not in response.json().get("traceback", "")
```

### E2E Test Pattern (playwright-python)
```python
from playwright.sync_api import Page, expect


def test_user_can_search_and_filter_markets(page: Page):
    page.goto("/")
    page.click('a[href="/markets"]')

    expect(page.locator("h1")).to_contain_text("Markets")

    page.fill('input[placeholder="Search markets"]', "election")
    page.wait_for_timeout(600)

    results = page.locator('[data-testid="market-card"]')
    expect(results).to_have_count(5, timeout=5000)

    first_result = results.first
    expect(first_result).to_contain_text("election", ignore_case=True)

    page.click('button:has-text("Active")')
    expect(results).to_have_count(3)


```

## Test File Organization

```
project/
├── src/
│   ├── models/
│   │   └── market.py
│   ├── services/
│   │   └── market.py
│   ├── api/
│   │   └── routers/
│   │       └── markets.py
│   └── main.py
├── tests/
│   ├── conftest.py                # Shared fixtures
│   ├── unit/
│   │   ├── test_models.py
│   │   └── test_services.py
│   ├── integration/
│   │   └── test_api_markets.py    # FastAPI TestClient tests
│   └── e2e/
│       ├── test_market_flow.py    # playwright-python tests
│       └── test_auth_flow.py
└── pyproject.toml
```

## Mocking External Services

### Database / SQLAlchemy Mock
```python
from unittest.mock import patch, MagicMock
from src.models import Market


@patch("src.services.market.get_session")
async def test_with_mocked_db(mock_get_session):
    mock_session = MagicMock()
    mock_session.execute.return_value.scalars.return_value.all.return_value = [
        Market(id=1, name="Test Market")
    ]
    mock_get_session.return_value.__aenter__.return_value = mock_session

    result = await market_service.list_all()
    assert len(result) == 1
```

### Redis Mock
```python
@patch("src.services.search.redis_client")
async def test_with_mocked_redis(mock_redis):
    mock_redis.search_by_vector.return_value = [
        {"slug": "test-market", "similarity_score": 0.95}
    ]

    results = await search_service.search("election")
    assert results[0]["slug"] == "test-market"
```

### LLM / Anthropic Mock
```python
from unittest.mock import Mock, patch


@patch("src.services.embedding.anthropic_client")
async def test_with_mocked_llm(mock_client):
    mock_client.messages.create.return_value = Mock(
        content=[Mock(text="Generated response")]
    )

    result = await embedding_service.generate("test input")
    assert result is not None
```

## Test Coverage Verification
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

## Common Testing Mistakes to Avoid

### WRONG: Testing Implementation Details
```python
# Don't test internal state
assert service._internal_count == 5
```

### CORRECT: Test User-Visible Behavior
```python
# Test observable output
result = service.get_count()
assert result == 5
```

### WRONG: Brittle Selectors
```python
# Breaks easily
page.click(".css-class-xyz")
```

### CORRECT: Semantic Selectors
```python
# Resilient to changes
page.click('button:has-text("Submit")')
page.click('[data-testid="submit-button"]')
```

### WRONG: No Test Isolation
```python
# Tests depend on each other
def test_creates_user(): ...
def test_updates_same_user(): ...  # depends on previous test!
```

### CORRECT: Independent Tests
```python
# Each test sets up its own data via fixtures
def test_creates_user(db_session):
    user = create_test_user(db_session)
    assert user.id is not None

def test_updates_user(db_session):
    user = create_test_user(db_session)
    user.name = "Updated"
    db_session.commit()
    assert user.name == "Updated"
```

## Continuous Testing

### Watch Mode During Development
```bash
# Using pytest-watch
ptw -- --cov=src
```

### Pre-Commit Hook
```bash
# .pre-commit-config.yaml — ruff (lint + format) + pytest
# See: https://github.com/astral-sh/ruff-pre-commit
pre-commit run --all-files
```

### CI/CD Integration
```yaml
# GitHub Actions
- name: Install dependencies
  run: uv sync --frozen
- name: Lint
  run: ruff check .
- name: Type check
  run: uvx pyright .
- name: Run Tests
  run: python3 -m pytest --cov=src --cov-report=xml
- name: Upload Coverage
  uses: codecov/codecov-action@v4
```

## Best Practices

1. **Write Tests First** - Always TDD
2. **One Assert Per Test** - Focus on single behavior
3. **Descriptive Test Names** - Explain what's tested
4. **Arrange-Act-Assert** - Clear test structure
5. **Mock External Dependencies** - Isolate unit tests
6. **Test Edge Cases** - None, empty, large values
7. **Test Error Paths** - Not just happy paths
8. **Keep Tests Fast** - Unit tests < 50ms each
9. **Clean Up After Tests** - No side effects
10. **Review Coverage Reports** - Identify gaps

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- E2E tests cover critical user flows
- Tests catch bugs before production

---

## Pre-PR Verification Checklist

Run these phases before creating a PR or after a significant change:

| Phase | Command | Action on Fail |
|-------|---------|----------------|
| **Lint** | `ruff check . && ruff format --check .` | STOP, fix first |
| **Types** | `uvx pyright .` | Fix critical errors |
| **Tests** | `python3 -m pytest --cov=src --cov-fail-under=80` | Must pass, 80%+ coverage |
| **Security** | grep for secrets, `print()` in src/ | Remove before PR |
| **Diff** | `git diff --stat` | Review unintended changes |

Produce a brief report: Lint/Types/Tests/Security — PASS or FAIL, then Overall: READY / NOT READY for PR.

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.
