#!/usr/bin/env node
// Adds one entry to the healing log.
// Spec: node_modules/coentrify/src/tools/specs/healing-append.md
import { execFileSync } from 'node:child_process';
import { appendFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { pathToFileURL } from 'node:url';

const DEFAULT_LOG = 'docs/records/healing-log.md';
const TITLE = '# Healing Log\n\n';
const PART_SEPARATOR = ' - ';
const USAGE = 'usage: healing-append.mjs <what went wrong> <what changed> [commit] [log]';

function currentCommit() {
  return execFileSync('git', ['rev-parse', '--short', 'HEAD'], { encoding: 'utf8' }).trim();
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

export function append({ log = DEFAULT_LOG, wrong, changed, commit, date = today() }) {
  const parts = [wrong, changed, commit].map((part) => (part ?? '').trim());
  for (const part of parts) {
    if (part === '') throw new Error('an entry has no empty part');
    if (part.includes(PART_SEPARATOR)) throw new Error('a part holds " - ", which would break the shape');
    if (part.includes(';')) throw new Error('a part holds a semicolon, and one entry holds one change');
  }
  if (!existsSync(log)) {
    mkdirSync(dirname(log), { recursive: true });
    writeFileSync(log, TITLE);
  }
  appendFileSync(log, `- ${[date, ...parts].join(PART_SEPARATOR)}\n`);
}

function main() {
  const [wrong, changed, commit, log] = process.argv.slice(2);
  if (wrong === undefined || changed === undefined) {
    console.error(USAGE);
    process.exit(1);
  }
  try {
    append({ log, wrong, changed, commit: commit ?? currentCommit() });
  } catch (error) {
    console.error(`healing append: ${error.message}`);
    process.exit(1);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main();
