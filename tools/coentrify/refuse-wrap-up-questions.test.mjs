import assert from 'node:assert/strict';
import { test } from 'node:test';
import { refusal } from './refuse-wrap-up-questions.mjs';

const RECAP = 'The hook is in place.';

const PASSES = {
  'a recap alone': { recap: RECAP },
  'an empty question': { recap: RECAP, ask: '' },
  'an empty list of options': { recap: RECAP, actions: [] },
};

const REFUSES = {
  'a question': { recap: RECAP, ask: 'Which fix first?' },
  'answer options': { recap: RECAP, actions: [{ label: 'Yes' }] },
  'a question with answer options': { recap: RECAP, ask: 'Go ahead?', actions: [{ action: 'commit' }] },
};

for (const [name, input] of Object.entries(PASSES)) {
  test(`passes: ${name}`, () => assert.equal(refusal(input), null));
}

for (const [name, input] of Object.entries(REFUSES)) {
  test(`refuses: ${name}`, () => assert.notEqual(refusal(input), null));
}
