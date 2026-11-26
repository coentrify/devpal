#!/usr/bin/env node
// Keeps coentrify.json true, and refuses a hand edit of a tracked standard.
// Spec: node_modules/coentrify/src/tools/specs/coentrify-json-check.md
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const CONFIG = 'coentrify.json';
const STATES = new Set(['tracked', 'customized']);
const WHO = new Set(['automatic', 'review']);
const AGENCY = new Set(['manual', 'assisted', 'guided', 'autonomous']);
const MODULE_SOURCE_KEY = 'source';
const STANDARD_EXTENSION = '.md';
const STAGED_FLAG = '--staged';

export function adopts(staged, last) {
  const listed = new Set();
  for (const [module, entries] of Object.entries(last?.modules ?? {})) {
    for (const standard of Object.keys(entries)) listed.add(`${module}/${standard}`);
  }
  for (const [module, entries] of Object.entries(staged?.modules ?? {})) {
    for (const standard of Object.keys(entries)) {
      if (standard !== MODULE_SOURCE_KEY && !listed.has(`${module}/${standard}`)) return true;
    }
  }
  return false;
}

export function problems(config, { root = '.', stagedPaths = null, versionChanged = false, adopted = false } = {}) {
  const found = [];
  const folders = config.folders ?? {};
  for (const [name, folder] of Object.entries(folders)) {
    if (!existsSync(join(root, folder))) found.push(`the ${name} folder ${folder} is missing`);
  }
  const standards = folders.standards ?? 'standards';
  const tracked = new Set();
  for (const [module, entries] of Object.entries(config.modules ?? {})) {
    for (const [standard, state] of Object.entries(entries)) {
      if (standard === MODULE_SOURCE_KEY) continue;
      const path = join(standards, module, standard + STANDARD_EXTENSION);
      if (!existsSync(join(root, path))) found.push(`the standard ${path} is not on disk`);
      if (!STATES.has(state)) found.push(`${module}/${standard} has the state ${state}`);
      if (state === 'tracked') tracked.add(path);
    }
  }
  if (config.healing !== undefined && !WHO.has(config.healing)) found.push(`healing is ${config.healing}`);
  if (config.update !== undefined && !WHO.has(config.update)) found.push(`update is ${config.update}`);
  if (config.agency !== undefined && !AGENCY.has(config.agency)) found.push(`agency is ${config.agency}`);
  if (config.filing !== undefined) {
    if (!WHO.has(config.filing)) found.push(`filing is ${config.filing}`);
    if (config.contributor !== true) found.push('filing stands without contributor: true');
  }
  for (const [name, library] of Object.entries(config.libraries ?? {})) {
    if (typeof library.source !== 'string') found.push(`the library ${name} has no source`);
    if (library.filing !== undefined && !WHO.has(library.filing)) found.push(`the library ${name} has the filing ${library.filing}`);
  }
  if (stagedPaths !== null && !versionChanged && !adopted) {
    for (const path of stagedPaths) {
      if (tracked.has(path)) found.push(`${path} is tracked and changed by hand. Set its state to customized, with the reason in the decisions`);
    }
  }
  return found;
}

function git(...args) {
  return execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
}

function committed(revision) {
  try {
    return JSON.parse(git('show', `${revision}:${CONFIG}`));
  } catch {
    return null;
  }
}

function main() {
  let config;
  try {
    config = JSON.parse(readFileSync(CONFIG, 'utf8'));
  } catch (error) {
    console.error(`coentrify.json check: ${CONFIG} does not parse: ${error.message}`);
    process.exit(1);
  }
  const options = {};
  if (process.argv.includes(STAGED_FLAG)) {
    options.stagedPaths = git('diff', '--cached', '--name-only').split('\n').filter(Boolean);
    const staged = committed('') ?? config;
    const last = committed('HEAD');
    options.versionChanged = last === null || last.version !== staged.version;
    options.adopted = adopts(staged, last);
  }
  const found = problems(config, options);
  if (found.length === 0) return;
  for (const problem of found) console.error(`coentrify.json check: ${problem}`);
  process.exit(1);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) main();
