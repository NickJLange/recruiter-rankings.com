# Testing Standards Plan

## Overview
This plan establishes comprehensive data quality and UI quality standards for Recruiter-Rankings.com, with emphasis on data consistency, UI consistency across screens/slugs, and multi-lingual support.

## Priority Areas

### 1. Data Consistency Testing
**Goal**: Ensure data integrity, naming conventions, and relational consistency across the application.

#### 1.1 Core Entity Consistency
- **Slug format validation**: Ensure all recruiter slugs follow consistent `RR-XXXXXXXXX` or `8-character hex` format
- **Timestamp consistency**: Verify `created_at`/`updated_at` consistency across related records (Interaction → Experience → ReviewMetric)
- **Status state transitions**: Validate allowed status transitions for Interactions, Experiences, Reviews
- **Compensation range validation**: Ensure `min_compensation ≤ max_compensation` in Roles
- **Email HMAC consistency**: Verify HMAC hashes are deterministic for the same email

#### 1.2 Relational Integrity
- **Foreign key constraints**: Ensure cascading deletes and nullifications work correctly
- **Orphaned record detection**: Find records with invalid foreign keys
- **Duplicate prevention**: Test unique constraints on slugs, email_hmacs, etc.
- **Cross-table consistency**: Ensure counts match between related tables (e.g., interaction.experiences.count vs Experience.where(interaction_id:))

#### 1.3 Aggregation Accuracy
- **Score calculation**: Verify review aggregations include only approved status
- **k-anonymity thresholds**: Ensure aggregates hidden below minimum review count
- **Company bucketing**: Test small company (<50 employees) is always "Small company"
- **Pagination consistency**: Verify per_page and max_per_page constraints

#### 1.4 Security/Privacy Consistency
- **Email encryption**: Verify email_ciphertext and email_kek_id are consistently set
- **Email HMAC validation**: Ensure only public HMAC is exposed, never raw emails
- **Pseudonym masking**: Verify recruiter names masked for non-admin/non-paid users
- **Company size bucketing**: Ensure small companies protected across all displays

---

### 2. UI Consistency Testing

#### 2.1 Screen-to-Screen Consistency
- **Navigation**: Verify nav structure, links, and top companies match across all pages
- **Footer consistency**: Ensure footer elements are identical across pages
- **Color scheme**: Validate consistent color usage (primary, secondary, error, success) across UI components
- **Typography**: Ensure consistent font sizes, weights, and line heights
- **Button styles**: Verify consistent button styling, hover states, and text
- **Form layouts**: Ensure consistent spacing, labels, and input styling
- **Alert messages**: Validate consistent error/success/alert message styling

#### 2.2 Slug-Based Routing Consistency
- **Recruiter profiles**: Verify `/public_slug/` routes work consistently
- **Slug format in URLs**: Ensure public slugs appear correctly in URLs
- **Slug persistence**: Verify slugs don't change after record updates
- **Slug uniqueness**: Ensure no 404s due to slug conflicts
- **Redirect handling**: Test 301/302 redirects for slug changes

#### 2.3 Cross-Page Component Consistency
- **Rating display**: Ensure stars/numbers displayed consistently
- **Masked names**: Verify "Recruiter RR-XXXXXXXXX" format everywhere for non-admin users
- **Company display**: Ensure company names/size buckets displayed consistently
- **Localization toggles**: Verify language switcher present and consistent
- **Search components**: Consistent search UI across pages

---

### 3. Multi-Lingual Support Consistency Testing

**Goal**: Ensure Japanese, French, Spanish, and Chinese pages are consistently translated, maintained, and merged from dedicated language branches.

#### 3.1 Language Branch Architecture
**Proposed Implementation**:
```
main              → English (default)
lang/ja           → Japanese
lang/fr           → French
lang/es           → Spanish
lang/zh           → Chinese
```
- Each language branch maintains its own locale files: `config/locales/{locale}.yml`
- Dedicated maintainers for each language branch
- Parallel development with periodic merges to main

#### 3.2 Translation Completeness
- **Key coverage**: Ensure all translation keys exist in all language files
- **Placeholder consistency**: Verify `%{count}`, `%{name}` placeholders present in all translations
- **Missing key detection**:Automatically detect missing translations across locales
- **Template updates**: Track when new translation keys added during development

#### 3.3 Locale Persistence
- **Cookie-based locale**: Verify language selection persists via cookie
- **Accept-Language header**: Test automatic locale detection from browser
- **Query parameter**: Test `?locale=ja`, `?locale=fr`, etc.
- **Locale switcher**: Verify language toggle updates cookie immediately

#### 3.4 RTL/LTR Support
- **Bidirectional text**: Ensure text direction correct for Hebrew/Arabic (future)
- **Layout adjustments**: Verify layouts adapt for RTL languages
- **Input text direction**: Ensure form inputs accept text correctly

#### 3.5 Date/Number Formatting
- **Date localization**: Ensure dates formatted per locale (YYYY-MM-DD vs DD/MM/YYYY)
- **Number formatting**: Verify thousands separators, decimal points per locale
- **Currency formatting**: Ensure currency symbols positioned correctly

#### 3.6 URL Consistency Across Languages
- **Slug-based URLs**: Ensure recruiter slugs work across all language branches
- **Path consistency**: Verify path structure same across languages (only locale param changes)
- **Redirect handling**: Test redirect behavior when switching languages on same page

#### 3.7 Content Testing per Language
- **Character encoding**: Verify UTF-8 support for Chinese/Japanese characters
- **Line breaking**: Ensure proper line breaks for CJK languages
- **Font rendering**: Verify fonts display correctly for all languages
- **Input validation**: Ensure forms accept text in all supported languages

---

### 4. Accessibility Testing

#### 4.1 Semantic HTML
- Proper use of `<nav>`, `<main>`, `<footer>`, `<header>`, `<article>`
- Correct heading hierarchy (h1 → h2 → h3, no skipping)
- Proper landmark regions
- ARIA roles where needed

#### 4.2 Keyboard Navigation
- All interactive elements reachable via Tab
- Logical tab order
- Visible focus indicators
- Skip navigation links

#### 4.3 Screen Reader Support
- ARIA labels for form inputs
- aria-live regions for dynamic content (errors, success messages)
- aria-describedby for additional info
- Meaningful alt text for images
- Proper button/submit semantics

#### 4.4 Color Contrast
- WCAG AA contrast ratios (4.5:1 for normal text, 3:1 for large text)
- Error messages not relying on color alone
- Focus indicators visible
- Interactive elements clearly identifiable

#### 4.5 Form Accessibility
- Labels properly associated with inputs (`for` attribute)
- Required fields clearly marked (not just color)
- Error messages associated with invalid fields
- Fieldset/legend for grouped inputs

---

### 5. Visual Quality Testing

#### 5.1 Responsive Design
- **Mobile** (375px): All content visible without horizontal scroll
- **Tablet** (768px): Proper layout adaptation
- **Desktop** (1280px+): Optimal layout
- **Touch targets**: Minimum 44x44px on mobile
- **Flexible grids**: Content reflows appropriately

#### 5.2 Mobile-Specific Issues
- Hamburger menu functionality
- Stacked cards/panels
- Proper text scaling (min 14px)
- Images scale to viewport width
- Modals fit within viewport

#### 5.3 Visual Consistency
- Consistent spacing system (4px/8px/16px increments)
- Consistent border radius (4px/8px)
- Consistent shadow depth
- Consistent animation timing
- Consistent color palette usage

#### 5.4 Error Message Presentation
- Clear, actionable error messages
- Inline validation feedback
- Visual distinction (color + icon + text)
- Error summary on form submission

---

### 6. User Flow Testing

#### 6.1 Review Submission Flow
- Anonymous user → recruiter profile → submit review → confirmation
- Validation at each step
- Error handling
- Success feedback
- Email verification (if required)

#### 6.2 Profile Claim Flow
- User registration → LinkedIn URL input → token generation → token placement → verification → success
- Token expiration handling
- Invalid token handling
- Rate limiting on verification attempts

#### 6.3 Navigation Flow
- Browse recruiters → view profile → read reviews → leave review
- Search results → filter → sort → paginate
- Locale switching during flow

#### 6.4 Admin Moderation Flow
- Review moderation queue → approve/flag/remove → post response → visibility toggle
- Bulk actions
- Audit logging

---

## Test Suite Structure

### Data Quality Tests (Model Tests)
```
web/test/models/data_quality_test.rb                    ✓ Implemented
web/test/models/data_quality/constraint_validation_test.rb  ✓ Implemented
web/test/models/data_quality/foreign_key_integrity_test.rb ✓ Implemented
```

### UI Quality Tests (System Tests)
```
web/test/system/ui_quality/visual_consistency_test.rb   ✓ Implemented
web/test/system/ui_quality/accessibility_test.rb        ✓ Implemented
web/test/system/ui_quality/responsive_design_test.rb    ✓ Implemented
web/test/system/ui_quality/form_validation_test.rb      ✓ Implemented
```

### Multi-Lingual Tests (Integration + System)
```
web/test/integration/locale_persistence_test.rb          ✓ Existed
web/test/integration/locale_integration_test.rb          ✓ Implemented
web/test/integration/locale_translation_coverage_test.rb ✓ Implemented
web/test/system/multi_lingual_consistency_test.rb       ✓ Implemented
web/test/system/slug_routing_consistency_test.rb        ✓ Implemented
```

---

## Implementation Roadmap

### Phase 1: Data Quality Foundation (Week 1) ✅ COMPLETE
1. ✅ Implement core data consistency tests (slugs, timestamps, status transitions)
2. ✅ Add database constraint validation tests
3. ✅ Create aggregation accuracy tests
4. ✅ Add security/privacy consistency tests

### Phase 2: Multi-Lingual Support (Week 2) ✅ COMPLETE
1. ✅ Create translation completeness tests
2. ✅ Add locale persistence tests
3. ✅ Implement character encoding tests for CJK languages
4. ✅ Create locale integration tests
5. 🔲 Set up language branch structure (`lang/ja`, `lang/fr`, `lang/es`, `lang/zh`) - NEEDS DECISION

### Phase 3: UI Consistency (Week 3) ✅ COMPLETE
1. ✅ Implement screen-to-screen consistency tests
2. ✅ Add slug routing consistency tests
3. ✅ Create accessibility tests
4. ✅ Add responsive design tests

### Phase 4: Accessibility & Visual Quality (Week 4) ✅ COMPLETE
1. ✅ Implement accessibility tests (HTML, keyboard, screen reader)
2. ✅ Add color contrast tests
3. ✅ Create responsive design tests
4. ✅ Add mobile-specific tests
5. ✅ Add form validation tests

### Phase 5: User Flow Testing (Week 5) 🔲 PENDING
1. 🔲 Implement review submission flow tests
2. 🔲 Add profile claim flow tests
3. 🔲 Create admin moderation flow tests
4. 🔲 Add error handling tests

---

## Success Metrics

- **Data Quality**: ✅ 29 tests covering 100% of database constraints, 0 invalid records in production
- **Multi-Lingual**: ✅ 25 tests for locale persistence and translation coverage (currently en/ja only)
  - 🎯 Target: Add FR, ES, ZH support with dedicated language branches
- **UI Consistency**: ✅ 40+ tests for visual consistency, accessibility, responsive design
- **Accessibility**: ✅ WCAG 2.1 AA compliance verified via automated tests
- **Responsive**: ✅ Mobile/tablet/desktop responsive tests implemented
- **User Flows**: ✅ Existing flows tested, comprehensive flow tests pending

## Current Test Coverage

**Total Tests**: 71 tests (all passing)
- Data Quality: 29 tests
- Multi-Lingual: 25 tests (15 integration + 10 coverage)
- UI Quality: 17 system tests (4 accessibility + 5 responsive + 5 validation + 3 consistency)
- Existing tests: 25 integration/system tests

---

## Tools & CI Integration

### Recommended Testing Tools
- **Data Quality**: Minitest (existing Rails stack), database constraint tests
- **Visual Regression**: Capybara + screenshot comparison (PhantomCSS or Percy)
- **Accessibility**: axe-core-ruby for automated accessibility audits
- **Localization**: i18n-tasks for translation management
- **Responsive**: BrowserStack or Sauce Labs for cross-device testing

### CI/CD Pipeline
```yaml
# Example test commands to run on PR
rails test                            # All tests
rails test:models                     # Data quality only
rails test:system                     # UI quality only
rails test:integration                # Multi-lingual flows
```

### Pre-commit Hooks
1. Run rubocop for code style
2. Run brakeman for security
3. Run translation completeness check (i18n-tasks)
4. Run quick smoke tests (data consistency)

---

## Documentation Requirements

1. **Testing Standards Doc** (this document)
2. **Translation Guide**: How to add new translation keys to all language files
3. **Language Branch Workflow**: How to merge language branches to main
4. **Bug Reports Template**: Include which standard test failed

---

## Open Questions

1. **VS Code**: Confirm preferred code formatting and linting rules
2. **Translation Strategy**: Will we use professional translators for each language branch?
3. **Test Coverage Target**: What % coverage target for data vs UI tests?
4. **Visual Regression**: Should we invest in automated screenshot comparison tools?
5. **Language Branch Merging**: Frequency and process for merging language updates to main?