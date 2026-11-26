#!/usr/bin/env node
// Refuses a commit message that holds AI attribution.
// Spec: node_modules/coentrify/src/tools/specs/attribution-check.md
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const ATTRIBUTION = /^\P{L}*(co-authored-by:|claude-session:|generated (with|by) \[?claude code)/iu;
const SCISSORS = /^# -+ >8 -+$/;
const USAGE = 'usage: attribution-check.mjs <commit message file>';

export function attribution(message) {
  for (const line of message.split('\n')) {
    if (SCISSORS.test(line)) break;
    if (ATTRIBUTION.test(line)) return line.trim();
  }
  return null;
}

export function attributionRefusal(message) {
  const line = attribution(message);
  if (line === null) return null;
  return `attribution check: "${line}" is attribution, and a commit message holds none (standards/commits/commits.md, No Attribution). Drop the line and commit again.`;
}

function main() {
  const [file] = process.argv.slice(2);
  if (file === undefined) {
    console.error(USAGE);
    process.exit(1);
  }
  const refusal = attributionRefusal(readFileSync(file, 'utf8'));
  if (refusal === null) return;
  console.error(refusal);
  process.exit(1);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main();
