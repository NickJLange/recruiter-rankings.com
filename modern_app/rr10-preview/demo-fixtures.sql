-- Only for the dedicated, newly created rr10_moderation_demo database.
CREATE TABLE rr10_demo_marker (marker text NOT NULL CHECK (marker = 'synthetic-only-rr10-v1'));
INSERT INTO rr10_demo_marker VALUES ('synthetic-only-rr10-v1');
INSERT INTO companies (name, created_at, updated_at) VALUES ('Demo Fictional Firm', now(), now());
INSERT INTO recruiters (name, public_slug, created_at, updated_at) VALUES ('Demo Fictional Recruiter', 'demo-fictional-recruiter', now(), now());
INSERT INTO users (email_hmac, role, created_at, updated_at)
SELECT 'rr10-demo-contributor-' || n, 'candidate', now(), now() FROM generate_series(1,5) n;
INSERT INTO users (email_hmac, role, created_at, updated_at) VALUES ('rr10-demo-moderator', 'moderator', now(), now());
DO $$
DECLARE kind text; contributor bigint; slot bigint; review bigint; dim text;
BEGIN
  FOR kind IN SELECT unnest(ARRAY['firm','recruiter']) LOOP
    FOR contributor IN SELECT id FROM users WHERE email_hmac IN ('rr10-demo-contributor-1','rr10-demo-contributor-2','rr10-demo-contributor-3','rr10-demo-contributor-4') LOOP
      INSERT INTO rr8_slots (company_id,recruiter_id,contributor_id) VALUES (CASE WHEN kind='firm' THEN 1 END, CASE WHEN kind='recruiter' THEN 1 END, contributor) RETURNING id INTO slot;
      INSERT INTO rr8_reviews (slot_id,rating,status) VALUES (slot,4,'approved') RETURNING id INTO review;
      UPDATE rr8_slots SET current_review_id=review WHERE id=slot;
      FOR dim IN SELECT unnest(ARRAY['responsiveness','role_clarity','candidate_needs','fairness','timeline','feedback_quality','professionalism','job_match']) LOOP
        INSERT INTO rr8_metrics (review_id,dimension,score) VALUES (review,dim,4);
      END LOOP;
    END LOOP;
  END LOOP;
END $$;
