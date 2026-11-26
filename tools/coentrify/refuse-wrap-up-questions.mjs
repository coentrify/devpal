#!/usr/bin/env node
// Refuses a wrap-up that carries a question or answer options.
// Spec: node_modules/coentrify/src/tools/specs/refuse-wrap-up-questions.md
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const REFUSE_EXIT_CODE = 2;
const REASON = 'the wrap-up carries the recap alone. Drop the ask and the actions, send the recap, and ask in the closing message as prose (Free Text Replies, No Buttons).';

export function refusal(toolInput) {
  const ask = toolInput?.ask;
  const actions = toolInput?.actions;
  const asks = typeof ask === 'string' && ask.trim() !== '';
  const offers = Array.isArray(actions) && actions.length > 0;
  return asks || offers ? REASON : null;
}

function main() {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  const reason = refusal(input?.tool_input);
  if (reason === null) return;
  console.error(`wrap-up questions: ${reason}`);
  process.exit(REFUSE_EXIT_CODE);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main();
