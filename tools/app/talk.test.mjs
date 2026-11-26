// The persona answers in its tone, and speaks in its voice clearly enough
// for the companion's own listening to understand it.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { homedir, tmpdir } from 'node:os'
import { join } from 'node:path'

const BINARY = new URL('../../app/.build/debug/Devpal', import.meta.url).pathname
const ROOT = new URL('../..', import.meta.url).pathname
const MODEL = join(homedir(), '.devpal/models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf')
// The first run downloads and compiles the models.
const TIMEOUT = 600_000

// The shipped persona and a memory of the test's own, never the machine's.
function run(...args) {
  return spawnSync(BINARY, ['--root', ROOT, '--persona', 'plain', ...args], { encoding: 'utf8', timeout: TIMEOUT })
}

const hasModel = { timeout: TIMEOUT, skip: existsSync(MODEL) ? false : `no talk model at ${MODEL}` }

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

function withMemory(check) {
  const folder = mkdtempSync(join(tmpdir(), 'devpal-'))
  try {
    return check(join(folder, 'memory.md'))
  } finally {
    rmSync(folder, { recursive: true, force: true })
  }
}

test('report for duty gets the plain persona\'s answer', hasModel, () => withMemory((memory) => {
  const result = run('--memory', memory, '--ask', 'Devpal, report for duty.')
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /sir,? yes,? sir/i)
}))

test('what it is told to remember, it keeps on the machine until told to forget', hasModel, () => withMemory((memory) => {
  const told = run('--memory', memory, '--ask', 'Remember that the demo ships on Friday.')
  assert.equal(told.status, 0, told.stderr)
  assert.match(readFileSync(memory, 'utf8'), /^- .*friday/im)
  const asked = run('--memory', memory, '--ask', 'When does the demo ship?')
  assert.match(asked.stdout, /friday/i)
  const forgot = run('--memory', memory, '--ask', 'Forget when the demo ships.')
  assert.equal(forgot.status, 0, forgot.stderr)
  assert.doesNotMatch(readFileSync(memory, 'utf8'), /friday/i)
}))

test('remember and forget are done in code, whatever the model would say', () => withMemory((memory) => {
  assert.equal(run('--memory', memory, '--ask', "Vibe One, don't forget that the logo needs work.").stdout.trim(), 'Noted.')
  assert.match(readFileSync(memory, 'utf8'), /^- The logo needs work\.$/m)
  assert.equal(run('--memory', memory, '--ask', 'Please forget about the logo.').stdout.trim(), 'Forgotten.')
  assert.doesNotMatch(readFileSync(memory, 'utf8'), /logo/)
  assert.equal(run('--memory', memory, '--ask', 'Forget the logo.').stdout.trim(), 'I had nothing on that.')
}))

test('report for duty is answered the same every time, without the model', () => withMemory((memory) => {
  for (const said of ['Report for duty.', 'Devpal, report for duty!']) {
    assert.equal(run('--memory', memory, '--ask', said).stdout.trim(), 'Sir, yes sir!')
  }
}))

test('sentences are sorted into question, order or chat', hasModel, () => {
  const cases = [
    ['How is the city map going?', 'question'],
    ['What does the wiki say about the factions?', 'question'],
    ['Fix the typo on the overview page.', 'order'],
    ['Start working on the next story.', 'order'],
    ['Tell me something funny.', 'chat'],
    ['What can you do for me?', 'chat'],
  ]
  const result = run(...cases.flatMap(([said]) => ['--classify', said]))
  assert.equal(result.status, 0, result.stderr)
  assert.deepEqual(result.stdout.trim().split('\n'), cases.map(([, intent]) => intent))
})

test('focus, back to base, and orders read back word for word, waiting for go', hasModel, () => withMemory((memory) => {
  const projects = mkdtempSync(join(tmpdir(), 'devpal-projects-'))
  try {
    spawnSync('mkdir', ['-p', join(projects, 'johnny-cyberquest')])
    const result = run('--memory', memory, '--projects', projects,
      '--ask', "Let's work on Johnny Cyberquest.",
      '--ask', 'Fix the typo on the overview page.',
      '--ask', 'Cancel.',
      '--ask', 'Clone the numb repo on this machine.',
      '--ask', 'No.',
      '--ask', 'Back to base.')
    assert.equal(result.status, 0, result.stderr)
    assert.deepEqual(result.stdout.trim().split('\n'), [
      'Focus on johnny-cyberquest.',
      'Order for johnny-cyberquest: Fix the typo on the overview page. Go?',
      'Cancelled.',
      'Clone numb onto this machine. Go?',
      'Cancelled.',
      'Back to base.',
    ])
  } finally {
    rmSync(projects, { recursive: true, force: true })
  }
}))
