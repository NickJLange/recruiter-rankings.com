import { describe, expect, it } from 'vitest';
import { aggregate, dimensions, parseReview, storageKey, transition } from './simulation';

describe('fictional browser-local moderation', () => {
  it('counts only the fixed fifth approved contributor and applies each category threshold', () => {
    const pending = transition(null, 'submit', { rating: 1, scores: { responsiveness: 5, fairness: 2 } });
    expect(aggregate(pending)).toBeNull();
    expect(() => transition(pending, 'submit', { rating: 5, scores: { fairness: 5 } })).toThrow();
    const approved = transition(pending, 'approve');
    expect(aggregate(approved)).toEqual({ count: 5, average: 3.4, dimensions: { responsiveness: 4.2, fairness: 3.6 } });
    expect(Object.keys(aggregate(approved)!.dimensions)).toHaveLength(2);
    expect(Object.keys(dimensions)).toHaveLength(8);
    expect(aggregate(transition(approved, 'remove'))).toBeNull();
    expect(() => transition(approved, 'approve')).toThrow();
    expect(() => transition(transition(approved, 'remove'), 'approve')).toThrow();
  });
  it('rejects malformed storage and separates target keys', () => {
    expect(storageKey('firm')).not.toBe(storageKey('recruiter'));
    expect(parseReview(null)).toBeNull();
    expect(() => parseReview('{')).toThrow();
    expect(() => parseReview(JSON.stringify({ status: 'approved', rating: 5, scores: { bogus: 5 } }))).toThrow();
    expect(() => transition(null, 'submit', { rating: 5, scores: {} })).toThrow();
  });
});
