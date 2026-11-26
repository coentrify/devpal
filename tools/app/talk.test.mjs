// The persona answers in its tone, and speaks in its voice clearly enough
// for the companion's own listening to understand it.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { existsSync, mkdtempSync, rmSync } from 'node:fs'
import { homedir, tmpdir } from 'node:os'
import { join } from 'node:path'

const BINARY = new URL('../../app/.build/debug/Devpal', import.meta.url).pathname
const ROOT = new URL('../..', import.meta.url).pathname
const MODEL = join(homedir(), '.devpal/models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf')
// The first run downloads and compiles the models.
const TIMEOUT = 600_000

function run(...args) {
  return spawnSync(BINARY, ['--root', ROOT, ...args], { encoding: 'utf8', timeout: TIMEOUT })
}

function words(text) {
  return text.toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').split(/\s+/).filter(Boolean).join(' ')
}

test('what the persona says comes back through listening as the same words', { timeout: TIMEOUT }, () => {
  const folder = mkdtempSync(join(tmpdir(), 'devpal-'))
  try {
    const file = join(folder, 'said.wav')
    const said = run('--say', 'Reporting for duty, ready for your orders.', '--to', file)
    assert.equal(said.status, 0, said.stderr)
    const heard = run('--hear', file)
    assert.equal(heard.status, 0, heard.stderr)
    assert.equal(words(heard.stdout), 'reporting for duty ready for your orders')
  } finally {
    rmSync(folder, { recursive: true, force: true })
  }
})

test('report for duty gets the plain persona\'s answer', {
  timeout: TIMEOUT,
  skip: existsSync(MODEL) ? false : `no talk model at ${MODEL}`,
}, () => {
  const result = run('--ask', 'Devpal, report for duty.')
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /sir,? yes,? sir/i)
})
