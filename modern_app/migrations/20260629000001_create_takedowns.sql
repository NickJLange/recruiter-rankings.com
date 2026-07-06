CREATE TYPE takedown_status AS ENUM ('pending', 'in_review', 'resolved', 'rejected');

CREATE TABLE takedown_requests (
    id SERIAL PRIMARY KEY,
    subject_type TEXT NOT NULL, -- 'Review' or 'Recruiter'
    subject_id INTEGER NOT NULL,
    requester_email TEXT NOT NULL,
    reason TEXT NOT NULL,
    status takedown_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_takedowns_subject ON takedown_requests(subject_type, subject_id);
CREATE INDEX idx_takedowns_status ON takedown_requests(status);
