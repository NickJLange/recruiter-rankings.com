# AI Agent Guidelines

## Engineering Preferences

These preferences shape all work on this project. Apply them before any other consideration.

- **DRY is about knowledge, not just text** — Flag logic duplication aggressively, but tolerate structural duplication if sharing it creates premature coupling (WET is better than the wrong abstraction).
- **Well-tested code is non-negotiable** — Test behavior, not implementation details. I prefer redundant coverage over missing edge cases, but ensure tests are resilient to refactoring.
- **Target "Engineered Enough"** — Handle current requirements + immediate edge cases. **Apply YAGNI**: do not build for hypothetical future use cases. Abstract only when you see the pattern for the third time (Rule of Three).
- **Err on the side of handling more edge cases, not fewer** — thoughtfulness > speed.
- **Bias toward explicit over clever.**

---

## Review Process (Plan Mode)

Before starting a review, you **MUST** ask:

> **BIG CHANGE or SMALL CHANGE?**
> 1. **BIG CHANGE**: Work through this interactively, one section at a time (Architecture → Code Quality → Tests → Performance) with at most 4 top issues in each section.
> 2. **SMALL CHANGE**: Work through interactively ONE question per review section.

### Review Sections

Walk through these four sections **in order**, presenting one section at a time. Wait for user feedback before proceeding to the next.

1. **Architecture review** — overall system design, component boundaries, dependency graph, coupling, data flow, scaling, security.
2. **Code quality review** — organization, module structure, DRY violations, error handling patterns, missing edge cases, tech debt hotspots, and over/under-engineering relative to preferences.
3. **Test review** — coverage gaps (unit, integration, e2e), test quality, assertion strength, missing edge cases, untested failure modes, and error paths.
4. **Performance review** — N+1 queries, database access patterns, memory-usage concerns, caching opportunities, slow or high-complexity code paths.

### Issue Format

For every specific issue (bug, smell, design concern, or risk):

- Describe the problem concretely, with file and line references.
- Present 2-3 options, including "do nothing" where reasonable.
- For each option, specify: implementation effort, risk, impact on other code, and **maintenance burden**.
- Give an opinionated recommendation and why, mapped to the engineering preferences.
- Explicitly ask whether the user agrees or wants a different direction before proceeding.

**Formatting Rules**:
- **NUMBER issues** (1, 2, 3...) and then give **LETTERS for options** (A, B, C...).
- The recommended option must always be the 1st option (Option A).
- When asking for selection, make sure each option clearly labels the issue NUMBER and option LETTER.

---

## Project Context (Read These First)

Do not duplicate content from these files. Reference them and read them at the start of any session.

| Document | Purpose | Read When |
|----------|---------|-----------|
| `openspec/project.md` | Canonical project definition (tech stack, entities, workflows, constraints) | Always — start here |
| `GEMINI.md` | Setup commands, env vars, configuration, development notes | Setting up or running locally |
| `gameplan.md` | Technical design, roadmap, threat model, monetization | Planning features or architecture |
| `TESTING_STANDARDS.md` | Test suite structure, coverage areas, quality standards | Writing or reviewing tests |

---

## OpenSpec Workflow Integration

This project uses the OpenSpec change management system for structured feature development.

- **Active changes**: `openspec/changes/` — proposals, specs, designs, and task lists in progress
- **Merged specs**: `openspec/specs/` — completed and accepted specifications
- **Workflow tools**: `.kilocode/workflows/opsx-*.md` — automation for the change lifecycle
- **New features**: Use the `opsx-new` workflow (proposal -> specs -> design -> tasks -> apply)
- **Continue work**: Use `opsx-continue` to resume an in-progress change

---

## Working Conventions

### Repository Structure

- `web/` — Ruby on Rails application (dynamic content, admin, API)
- `site/` — Jekyll static site (marketing pages, builds to `web/public/`)
- `openspec/` — Project specs and change management

### Handoff Signal

At the end of any response, use one of two explicit signals — no signal means work is not done:

- **"✅ Ready to test"** — all code changes are complete, tests pass, nothing more to do before manual verification.
- **"⏳ Next step: [what's coming]"** — more automated work is in progress; do not start manual testing yet.

### Verification

Run these commands from `web/` before any code change is considered complete:

```bash
# Unit + integration tests (pre-existing 5F/2E from locale/any_instance issues are acceptable)
PARALLEL_WORKERS=1 bundle exec rails test

# End-to-end browser tests (requires headless Chrome / cuprite)
PARALLEL_WORKERS=1 bundle exec rails test:system
```

`PARALLEL_WORKERS=1` is required to avoid Ruby/pg segfaults with the pg gem.

- Verify changes locally before committing
- For `site/`: run `bundle exec jekyll build` to verify static site builds

### Documentation Maintenance

- `openspec/project.md` is the canonical source of truth for project definition — update it, not duplicates elsewhere
- Keep documentation DRY: if information exists in one doc, reference it from others rather than copying
- When project fundamentals change (stack versions, entities, workflows), update `openspec/project.md` first

---

## Testing Standards

Key principles (full details in `TESTING_STANDARDS.md`):

- **Framework**: Minitest (Rails built-in) with parallel execution
- **Primary focus**: Integration tests covering user flows
- **System tests**: Capybara + Selenium for end-to-end browser testing
- **Data quality**: Database constraint validation, relational integrity, aggregation accuracy
- **Multi-lingual**: Translation completeness, locale persistence, character encoding
- Run `rails test` for the full suite; `rails test:integration` for integration only
