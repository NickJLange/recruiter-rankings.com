# AI Agent Guidelines

## Engineering Preferences

These preferences shape all work on this project. Apply them before any other consideration.

- **DRY is important** — flag repetition aggressively across code, docs, and specs
- **Well-tested code is non-negotiable** — too many tests is better than too few
- **"Engineered enough"** — not under-engineered (fragile, missing edge cases) or over-engineered (premature abstraction, speculative generality)
- **Handle more edge cases, not fewer** — thoughtfulness over speed
- **Explicit over clever** — readable code wins; avoid magic unless the framework demands it

---

## Review Process (Plan Mode)

Before starting a review, ask:

> **BIG CHANGE or SMALL CHANGE?**
> - **BIG CHANGE**: Up to 4 top issues per section, interactive section-by-section
> - **SMALL CHANGE**: 1 issue per section, compact format

### Review Sections

Walk through these four sections **in order**, presenting one section at a time. Wait for user feedback before proceeding to the next.

1. **Architecture** — system design, component boundaries, coupling, data flow, scaling, security
2. **Code Quality** — organization, DRY violations, error handling, tech debt, engineering balance
3. **Tests** — coverage gaps, quality, edge cases, untested failure modes
4. **Performance** — N+1 queries, memory, caching, slow code paths

### Issue Format

Each issue within a section follows this structure:

```
### Issue N: [Concrete description]

**Location**: `file_path:line_number` (or range)
**Impact**: [What breaks, degrades, or is at risk]

**Options**:
  A) [Option] — Effort: [low/med/high] | Risk: [low/med/high] | Impact: [low/med/high]
  B) [Option] — Effort: [low/med/high] | Risk: [low/med/high] | Impact: [low/med/high]
  C) Do nothing — [Why this might be acceptable]

**Recommendation**: [Letter] — [Why this is the best choice]

**Your call?** [A / B / C]
```

- Number issues (1, 2, 3, 4) and letter options (A, B, C) for unambiguous selection
- Always include a "do nothing" option with honest rationale
- Be opinionated — state a recommendation, don't just list options
- Use `file:line` references so the user can jump to the code

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

### Verification

- Run `rails test` from `web/` before any code change is considered complete
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
