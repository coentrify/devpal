import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { append } from './healing-append.mjs';

function newLog() {
  return join(mkdtempSync(join(tmpdir(), 'healing-')), 'records', 'healing-log.md');
}

test('two appends give two lines in the same shape, under the title', () => {
  const log = newLog();
  append({ log, wrong: 'a commit followed a git add', changed: 'the gate checks it', commit: 'abc1234', date: '2026-11-21' });
  append({ log, wrong: 'a link pointed nowhere', changed: 'the unlink script runs', commit: 'def5678', date: '2026-11-22' });
  assert.equal(
    readFileSync(log, 'utf8'),
    '# Healing Log\n\n- 2026-11-21 - a commit followed a git add - the gate checks it - abc1234\n- 2026-11-22 - a link pointed nowhere - the unlink script runs - def5678\n',
  );
});

for (const wrong of ['one - two', 'one; two', '']) {
  test(`refuses the part "${wrong}" and changes nothing`, () => {
    const log = newLog();
    assert.throws(() => append({ log, wrong, changed: 'x', commit: 'abc1234' }));
    assert.equal(existsSync(log), false);
  });
}
