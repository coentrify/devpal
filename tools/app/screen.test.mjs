// The screen renders its three layers to a PNG, and a missing layer fails at once.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

const BINARY = new URL('../../app/.build/debug/Devpal', import.meta.url).pathname
const ROOT = new URL('../..', import.meta.url).pathname
const PNG_SIGNATURE = '89504e470d0a1a0a'

function run(...args) {
  return spawnSync(BINARY, ['--root', ROOT, ...args], { encoding: 'utf8' })
}

function pngSize(file) {
  const bytes = readFileSync(file)
  assert.equal(bytes.subarray(0, 8).toString('hex'), PNG_SIGNATURE)
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) }
}

test('a snapshot of the background, the persona, the filter and a subtitle is a PNG of the asked size', () => {
  const folder = mkdtempSync(join(tmpdir(), 'devpal-'))
  try {
    const file = join(folder, 'screen.png')
    const result = run('--snapshot', file, '--size', '320x200', '--subtitle', 'Sir, yes sir!')
    assert.equal(result.status, 0, result.stderr)
    assert.deepEqual(pngSize(file), { width: 320, height: 200 })
  } finally {
    rmSync(folder, { recursive: true, force: true })
  }
})

test('a layer that does not exist names the missing file', () => {
  const result = run('--persona', 'nobody', '--snapshot', join(tmpdir(), 'devpal-never.png'))
  assert.equal(result.status, 1)
  assert.match(result.stderr, /missing .*personas\/nobody/)
})

test('an unknown option prints the usage', () => {
  const result = run('--loud')
  assert.equal(result.status, 2)
  assert.match(result.stderr, /Usage: devpal/)
})
