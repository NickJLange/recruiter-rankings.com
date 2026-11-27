import pg from 'pg';
import assert from 'node:assert/strict';
const url = process.env.PREVIEW_URL;
if (!url || !process.env.DATABASE_URL?.endsWith('/rr10_preview')) throw new Error('Set PREVIEW_URL and disposable rr10_preview DATABASE_URL');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const paths = [ ['/firm/2', 'Evergreen Fictional Search'], ['/recruiter/fictional-theo', 'Theo Fictional Vale'] ];
try {
  const rows = await pool.query(`SELECT r.id FROM rr8_reviews r JOIN rr8_slots s ON s.id = r.slot_id
    JOIN users u ON u.id = s.contributor_id WHERE u.email_hmac = 'fictional-private-contributor-5'
    AND (s.company_id = 2 OR s.recruiter_id = 2) ORDER BY r.id`);
  assert.equal(rows.rowCount, 2);
  for (const [state, status] of [['four', 'pending'], ['five', 'approved'], ['removed', 'removed']]) {
    await pool.query('UPDATE rr8_reviews SET status = $1 WHERE id = ANY($2::bigint[])', [status, rows.rows.map(r => r.id)]);
    for (const [path, name] of paths) {
      const response = await fetch(new URL(path, url), { cache: 'no-store', headers: { 'User-Agent': 'Googlebot' } });
      const html = await response.text();
      assert.equal(response.status, 200); assert.match(response.headers.get('cache-control') ?? '', /no-store/);
      assert.match(response.headers.get('x-robots-tag') ?? '', /noindex/);
      assert.ok(html.includes(name));
      assert.ok(html.includes(`rel="canonical" href="${new URL(path, url).href}"`));
      const match = html.match(/<script type="application\/ld\+json">(.*?)<\/script>/);
      assert.ok(match, `missing JSON-LD for ${path}`);
      const data = JSON.parse(match[1]);
      assert.equal(data.name, name); assert.equal(data.url, new URL(path, url).href);
      assert.deepEqual(Object.keys(data).sort(), ['@context', '@type', ...(state === 'five' ? ['aggregateRating'] : []), 'name', 'url'].sort());
      if (state === 'five') { assert.deepEqual(Object.keys(data.aggregateRating).sort(), ['@type', 'ratingValue', 'ratingCount', 'bestRating', 'worstRating'].sort()); assert.equal(data.aggregateRating.ratingCount, 5); assert.equal(data.aggregateRating.ratingValue, 4.8); }
      else assert.equal(data.aggregateRating, undefined);
      for (const secret of ['FICTIONAL_PRIVATE_TEXT_SENTINEL', 'fictional-private-contributor', 'fictional-private-moderator', 'transparency']) assert.ok(!html.includes(secret), `${state} ${path} leaked ${secret}`);
      if (state === 'five') { assert.ok(html.includes('4.8')); assert.match(html.replace(/<[^>]*>/g, ''), /5\s+approved contributions/); assert.ok(html.includes('communication')); }
      else { assert.ok(!html.includes('approved contributions')); assert.ok(!html.includes('4.8')); assert.ok(!html.includes('OVERALL SCORE')); }
      console.log(`${state} ${path}: 200 name=yes score=${state === 'five' ? '4.8' : 'withheld'} sparse-category=withheld private=absent cache=no-store`);
    }
  }
  for (const path of ['/search', '/person/fictional-theo', '/reviews/new', '/takedown']) {
    const response = await fetch(new URL(path, url), { redirect: 'manual' });
    assert.equal(response.status, 404); console.log(`legacy ${path}: 404`);
  }
  const search = await fetch(new URL('/?q=Evergreen', url));
  const html = await search.text(); assert.ok(html.includes('Evergreen Fictional Search')); assert.ok(!html.includes('Mara Fictional Lane'));
  assert.ok(html.includes(`rel="canonical" href="${new URL('/', url).href}"`));
  console.log('directory search Evergreen: firm present, unrelated recruiter absent');
  const methodology = await fetch(new URL('/methodology', url));
  const methodHtml = await methodology.text(); assert.equal(methodology.status, 200);
  assert.ok(methodHtml.includes(`rel="canonical" href="${new URL('/methodology', url).href}"`));
  assert.match(methodHtml, /distinct contributors/); assert.match(methodHtml, /Each category independently/);
  const sitemap = await (await fetch(new URL('/sitemap.xml', url))).text();
  const locations = [...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map(m => m[1]).sort();
  assert.deepEqual(locations, ['/', '/methodology', '/firm/1', '/firm/2', '/recruiter/fictional-mara', '/recruiter/fictional-theo'].map(path => new URL(path, url).href).sort());
  console.log('methodology, canonical URLs and synthetic sitemap: OK');
} finally { await pool.end(); }
