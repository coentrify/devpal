import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { adopts, problems } from './coentrify-json-check.mjs';

const STANDARD = 'standards/behavior/understand-the-need.md';

function project() {
  const root = mkdtempSync(join(tmpdir(), 'coentrify-json-'));
  mkdirSync(join(root, 'docs'));
  mkdirSync(join(root, 'standards', 'behavior'), { recursive: true });
  writeFileSync(join(root, STANDARD), '# Understand The Need\n');
  return root;
}

function config(changes = {}) {
  return {
    version: '0.1.0',
    folders: { docs: 'docs', standards: 'standards' },
    healing: 'automatic',
    modules: { behavior: { 'understand-the-need': 'tracked' } },
    ...changes,
  };
}

function count(changes, options = {}) {
  return problems(config(changes), { root: project(), ...options }).length;
}

test('a file that names its folders and lists standards on disk passes', () => assert.equal(count(), 0));
test('a missing folder fails', () => assert.equal(count({ folders: { docs: 'none', standards: 'standards' } }), 1));
test('a missing standard fails', () => assert.equal(count({ modules: { behavior: { gone: 'tracked' } } }), 1));
test('a state of draft fails', () => assert.equal(count({ modules: { behavior: { 'understand-the-need': 'draft' } } }), 1));
test('a healing of sometimes fails', () => assert.equal(count({ healing: 'sometimes' }), 1));
test('an update of daily fails', () => assert.equal(count({ update: 'daily' }), 1));
test('an update of review passes', () => assert.equal(count({ update: 'review' }), 0));
test('an agency of wild fails', () => assert.equal(count({ agency: 'wild' }), 1));
test('an agency of guided passes', () => assert.equal(count({ agency: 'guided' }), 0));
test('filing without contributor fails', () => assert.equal(count({ filing: 'review' }), 1));
test('filing beside contributor passes', () => assert.equal(count({ filing: 'review', contributor: true }), 0));
test('a library with a source and a filing passes', () => assert.equal(count({ libraries: { lib: { source: 'https://example.com', filing: 'review' } } }), 0));
test('a library without a source fails', () => assert.equal(count({ libraries: { lib: { filing: 'review' } } }), 1));
test('a module with a source of its own passes', () => assert.equal(count({ modules: { behavior: { source: 'https://example.com', 'understand-the-need': 'tracked' } } }), 0));
test('a commit that edits a tracked standard by hand refuses', () => assert.equal(count({}, { stagedPaths: [STANDARD] }), 1));
test('it passes once the state is customized', () => assert.equal(count({ modules: { behavior: { 'understand-the-need': 'customized' } } }, { stagedPaths: [STANDARD] }), 0));
test('a commit that edits tracked standards and changes the version passes', () => assert.equal(count({}, { stagedPaths: [STANDARD], versionChanged: true }), 0));
test('a commit that adopts a standard and edits tracked standards passes', () => {
  const adopted = adopts(config({ modules: { behavior: { 'understand-the-need': 'tracked', 'note-issues': 'tracked' } } }), config());
  assert.equal(count({}, { stagedPaths: [STANDARD], adopted }), 0);
});
test('a commit that changes coentrify.json without adopting a standard, and edits a tracked standard, refuses', () => {
  const adopted = adopts(config({ healing: 'review' }), config());
  assert.equal(count({}, { stagedPaths: [STANDARD], adopted }), 1);
});
test('a module source added is no adoption', () => assert.equal(adopts(config({ modules: { behavior: { source: 'https://example.com', 'understand-the-need': 'tracked' } } }), config()), false));
test('a first coentrify.json adopts what it lists', () => assert.equal(adopts(config(), null), true));
