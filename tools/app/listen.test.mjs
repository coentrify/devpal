// What is said is cut into sentences and transcribed on the machine, with
// the special words spelled right. The speech is the Mac's own voice.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

const BINARY = new URL('../../app/.build/debug/Devpal', import.meta.url).pathname
const ROOT = new URL('../..', import.meta.url).pathname
// The first run downloads and compiles the models.
const TIMEOUT = 600_000

function words(text) {
  return text.toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').split(/\s+/).filter(Boolean).join(' ')
}

function hear(sentence) {
  const folder = mkdtempSync(join(tmpdir(), 'devpal-'))
  try {
    const file = join(folder, 'speech.wav')
    const spoken = spawnSync('say', ['-v', 'Samantha', '-o', file, '--data-format=LEI16@16000', sentence])
    assert.equal(spoken.status, 0, String(spoken.stderr))
    const result = spawnSync(BINARY, ['--root', ROOT, '--hear', file], { encoding: 'utf8', timeout: TIMEOUT })
    assert.equal(result.status, 0, result.stderr)
    return result.stdout.trim()
  } finally {
    rmSync(folder, { recursive: true, force: true })
  }
}

test('a spoken sentence comes back as its words', { timeout: TIMEOUT }, () => {
  assert.equal(words(hear('Push the changes to main and run the checks.')), 'push the changes to main and run the checks')
})

test('its own name is spelled as the word list spells it', { timeout: TIMEOUT }, () => {
  assert.match(hear('Devpal, report for duty.'), /\bDevpal\b/i)
})

test('after a short first sentence, the next one is heard too', { timeout: TIMEOUT }, () => {
  const lines = hear('Hi. [[slnc 1000]] How are you doing today?').split('\n').map(words)
  assert.deepEqual(lines, ['hi', 'how are you doing today'])
})
