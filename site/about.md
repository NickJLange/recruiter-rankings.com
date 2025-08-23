---
layout: default
i18n_key: about
title: About — Recruiter Rankings
description: "Learn how Recruiter Rankings works: users, identity verification, policies, and roadmap."
---

## Mission
Improve the recruiter–candidate experience by publishing de‑identified, standardized quality signals with a safe right‑of‑reply.

## Primary users
- Candidates: browse aggregates; submit reviews
- Recruiters: claim profile; right‑of‑reply
- Moderators/Admin: moderation and takedowns

## Identity & verification (POC)
- LinkedIn profile challenge with a one‑time token (128‑bit), TTL 7 days
- No plaintext tokens stored; hashed only; rate‑limited fetching

## Data & privacy
- Public uses only aggregates; no PII
- Email handling with HMAC reference publicly; raw email encrypted at rest via envelope encryption
- PII retention (POC): 180 days; abuse metadata 30 days; logs redact PII

## Roadmap
- POC: core models, reviews, verification, moderation, public directory
- Beta: claims, right‑of‑reply UI, suppression thresholds, B2B skeleton
- GA: expanded compliance, regional isolation, pricing/payments, hardened anti‑abuse

