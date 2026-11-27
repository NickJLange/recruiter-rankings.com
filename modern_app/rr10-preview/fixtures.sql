-- Only load into a new disposable database. Entirely fictional people and organizations.
INSERT INTO companies (name, created_at, updated_at) VALUES ('Northstar Fictional Talent', now(), now()), ('Evergreen Fictional Search', now(), now());
INSERT INTO recruiters (name, public_slug, created_at, updated_at) VALUES ('Mara Fictional Lane', 'fictional-mara', now(), now()), ('Theo Fictional Vale', 'fictional-theo', now(), now());
INSERT INTO users (email_hmac, role, created_at, updated_at)
SELECT 'fictional-private-contributor-' || n, 'candidate', now(), now() FROM generate_series(1, 5) AS n;
INSERT INTO users (email_hmac, role, created_at, updated_at) VALUES ('fictional-private-moderator', 'moderator', now(), now());
DO $$
DECLARE target_kind text; target_id bigint; contributor bigint; slot bigint; review bigint; n integer;
BEGIN
  FOR target_kind, target_id IN SELECT 'recruiter', id FROM recruiters UNION ALL SELECT 'firm', id FROM companies LOOP
    FOR n IN 1..5 LOOP
      SELECT id INTO contributor FROM users WHERE email_hmac = 'fictional-private-contributor-' || n;
      INSERT INTO rr8_slots (recruiter_id, company_id, contributor_id)
        VALUES (CASE WHEN target_kind = 'recruiter' THEN target_id END, CASE WHEN target_kind = 'firm' THEN target_id END, contributor) RETURNING id INTO slot;
      INSERT INTO rr8_reviews (slot_id, rating, status) VALUES (slot, CASE WHEN n = 1 THEN 4 ELSE 5 END,
        CASE WHEN (target_kind = 'recruiter' AND target_id = 1) OR (target_kind = 'firm' AND target_id = 1) OR n < 5 THEN 'approved' ELSE 'pending' END) RETURNING id INTO review;
      UPDATE rr8_slots SET current_review_id = review WHERE id = slot;
      INSERT INTO rr8_metrics (review_id, dimension, score) VALUES (review, 'communication', CASE WHEN n = 1 THEN 4 ELSE 5 END);
      IF n < 5 THEN INSERT INTO rr8_metrics (review_id, dimension, score) VALUES (review, 'transparency', 4); END IF;
    END LOOP;
  END LOOP;
END $$;
-- A private legacy sentinel proves the preview is not rendering individual review text.
INSERT INTO interactions (recruiter_id, target_id, created_at, updated_at) VALUES (1, 1, now(), now());
INSERT INTO experiences (interaction_id, rating, status, body, created_at, updated_at)
VALUES (currval('interactions_id_seq'), 1, 'approved', 'FICTIONAL_PRIVATE_TEXT_SENTINEL', now(), now());
