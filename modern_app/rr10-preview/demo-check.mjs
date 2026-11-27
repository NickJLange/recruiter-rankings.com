// Run only against the disposable shared demo: this resets both fictional targets.
import assert from 'node:assert/strict';

const origin = process.env.RR10_PREVIEW_ORIGIN;
if (!origin || new URL(origin).origin !== origin) throw new Error('Set RR10_PREVIEW_ORIGIN to the exact demo origin');
const post = async (params, requestOrigin = origin) => fetch(`${origin}/demo/action`, {
  method: 'POST', redirect: 'manual', headers: { Origin: requestOrigin, 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams(params),
});
const page = async (path) => (await fetch(`${origin}${path}`)).text();
const hidden = async (path) => assert.match(await page(path), /Getting the full picture/);

for (const [kind, path] of [['firm', '/firm/1'], ['recruiter', '/recruiter/demo-fictional-recruiter']]) {
  const reset = () => post({ kind, action: 'reset' });
  try {
    assert.equal((await reset()).status, 303);
    assert.equal((await post({ kind, action: 'submit', rating: '5' })).status, 400);
    assert.equal((await post({ kind, action: 'reset', user: '1' })).status, 400);
    assert.equal((await post({ kind, action: 'reset' }, 'https://invalid.example')).status, 403);
    await hidden(path);
    const input = { kind, action: 'submit', rating: '1', responsiveness: '5' };
    const submissions = await Promise.all([post(input), post(input)]);
    assert.deepEqual(submissions.map(r => r.status).sort(), [303, 409]);
    const moderatorView = async () => {
      const html = (await page(`/demo?kind=${kind}`)).replaceAll('<!-- -->', '');
      assert.match(html, /<dt>Overall score<\/dt><dd>1 \/ 5<\/dd>/);
      assert.match(html, /<dt>Responsiveness<\/dt><dd>5 \/ 5<\/dd>/);
      assert.match(html, /<dt>Clarity and accuracy of role description<\/dt><dd>N\/A<\/dd>/);
    };
    await moderatorView();
    await hidden(path);
    assert.doesNotMatch(await page(path), /moderator-review|Fictional contribution to review/);
    assert.equal((await post({ kind, action: 'approve' })).status, 303);
    await moderatorView();
    const approved = await page(path);
    assert.match(approved, /<strong>3\.4<\/strong>/);
    assert.match(approved, /approved contributions/);
    assert.match(approved, /<dt>responsiveness<\/dt><dd>4\.2/);
    assert.doesNotMatch(approved, /moderator-review|Fictional contribution to review|<dt>role clarity<\/dt>/i);
    assert.equal((await post({ kind, action: 'remove' })).status, 303);
    await moderatorView();
    await hidden(path);
    console.log(`${kind}: moderator sees 1 overall, 5 responsiveness and N/A; public hidden → 3.4 / 4.2 → hidden; duplicate rejected`);
  } finally {
    await reset();
  }
}
