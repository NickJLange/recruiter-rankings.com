-- Disposable RR-8 candidate schema only; not a production migration.
CREATE TABLE rr8_slots (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  recruiter_id bigint REFERENCES recruiters(id),
  company_id bigint REFERENCES companies(id),
  contributor_id bigint NOT NULL REFERENCES users(id),
  current_review_id bigint,
  CHECK (num_nonnulls(recruiter_id, company_id) = 1),
  UNIQUE (recruiter_id, contributor_id),
  UNIQUE (company_id, contributor_id)
);
CREATE TABLE rr8_submissions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  contributor_id bigint NOT NULL REFERENCES users(id),
  submitted_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX ON rr8_submissions (contributor_id, submitted_at);
CREATE TABLE rr8_reviews (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slot_id bigint NOT NULL REFERENCES rr8_slots(id),
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  status text NOT NULL CHECK (status IN ('pending', 'approved', 'removed')),
  UNIQUE (id, slot_id)
);
ALTER TABLE rr8_slots ADD CONSTRAINT rr8_current_review_fk
  FOREIGN KEY (current_review_id, id) REFERENCES rr8_reviews(id, slot_id)
  ON DELETE SET NULL (current_review_id);
CREATE TABLE rr8_metrics (
  review_id bigint NOT NULL REFERENCES rr8_reviews(id) ON DELETE CASCADE,
  dimension text NOT NULL CHECK (dimension ~ '^[a-z_]+$'),
  score integer NOT NULL CHECK (score BETWEEN 1 AND 5),
  PRIMARY KEY (review_id, dimension)
);
CREATE TABLE rr8_moderation_decisions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  review_id bigint NOT NULL,
  moderator_id bigint NOT NULL REFERENCES users(id),
  decision text NOT NULL CHECK (decision IN ('approve', 'remove')),
  decided_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
