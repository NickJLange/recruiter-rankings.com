## ADDED Requirements

### Requirement: Synthetic structured feedback lifecycle
The demo SHALL permit an explicitly simulated contributor to submit an overall score and at least one of eight dimension scores for a bounded fictional firm or recruiter, and an explicitly simulated moderator to approve or remove it. Remaining dimensions may be N/A.

#### Scenario: Threshold transition
- **WHEN** the fifth distinct fictional contributor is submitted, approved, and removed
- **THEN** the public aggregate remains hidden while pending, appears upon approval, and is suppressed after removal.

### Requirement: Isolated and bounded mutations
The demo SHALL reject mutations outside an explicitly enabled, locally verified disposable database, and SHALL validate target, actor, input and same-origin browser requests. It SHALL disclose shared simulated roles and state.
