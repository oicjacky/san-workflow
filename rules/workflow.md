# Development Workflow

## Pipeline
Research → Plan → TDD (Red/Green/Refactor) → Code Review → Commit (+ Feature Doc & Changelog)

以下文件不受 pipeline 階段限制，符合條件即建立：
Issue report、Ticket、Handoff note

## Docs
遵循 `skills/docs-management/SKILL.md` 的完整規則。

| Doc Type | 觸發時機 |
|----------|---------|
| Feature doc | `feat:`/`fix:`/`refactor:` commit 符合 SKILL.md 條件時 |
| Issue report | 發現 bug 或非預期行為時 |
| Ticket | 需要追蹤待辦工作時 |
| Handoff note | Session 結束前有未完成工作時 |
| Changelog | Feature complete 或 Issue fixed 時 |

## Research & Reuse (mandatory before new implementation)
- WebSearch / WebFetch 搜尋現有方案
- Library docs: Context7 MCP
- Check package registries (npm, PyPI) before writing utilities
- Prefer adopting proven approaches over net-new code
