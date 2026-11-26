import assert from 'node:assert/strict'
import fs from 'node:fs'
import http from 'node:http'
import os from 'node:os'
import path from 'node:path'
import { test } from 'node:test'
import { chosenNames, findWikis, handler, homeAddress, hostName, projectsFolder, resolveFile, wikiFor } from './wikis.mjs'

const scratch = () => fs.mkdtempSync(path.join(os.tmpdir(), 'devpal-wikis-'))

function write(file, text = '') {
  fs.mkdirSync(path.dirname(file), { recursive: true })
  fs.writeFileSync(file, text)
}

test('a project has a wiki when it has a .vitepress folder, in docs or at its root', () => {
  const root = scratch()
  fs.mkdirSync(path.join(root, 'addix', 'docs', '.vitepress'), { recursive: true })
  fs.mkdirSync(path.join(root, 'johnny-cyberquest', '.vitepress'), { recursive: true })
  fs.mkdirSync(path.join(root, 'numb', 'docs'), { recursive: true })
  fs.mkdirSync(path.join(root, 'Cult Of Personality', 'docs', '.vitepress'), { recursive: true })
  const found = findWikis(root).map((w) => [w.name, w.source])
  assert.deepEqual(found, [['addix', 'docs'], ['cult-of-personality', 'docs'], ['johnny-cyberquest', '.']])
})

test('a missing projects folder has no wikis', () => {
  assert.deepEqual(findWikis(path.join(scratch(), 'nothing')), [])
})

test('a name is the folder name in lowercase letters, digits and dashes', () => {
  assert.equal(hostName('Johnny_Cyberquest'), 'johnny-cyberquest')
  assert.equal(hostName('addix'), 'addix')
})

test('the projects folder comes from the machine config, else ~/dev', () => {
  const dir = scratch()
  const config = path.join(dir, 'config.json')
  write(config, JSON.stringify({ projects: '~/work' }))
  assert.equal(projectsFolder(config), path.join(os.homedir(), 'work'))
  assert.equal(projectsFolder(path.join(dir, 'none.json')), path.join(os.homedir(), 'dev'))
})

test('the name a request was sent to picks the wiki', () => {
  assert.equal(wikiFor('addix.local', ['addix']), 'addix')
  assert.equal(wikiFor('Addix.local:80', ['addix']), 'addix')
  assert.equal(wikiFor('numb.local', ['addix']), null)
  assert.equal(wikiFor('192.168.2.10', ['addix']), null)
})

test('a path finds its page the way the wiki links it', () => {
  const dir = scratch()
  write(path.join(dir, 'index.html'))
  write(path.join(dir, 'features', 'camera.html'))
  write(path.join(dir, 'features', 'index.html'))
  assert.equal(resolveFile(dir, '/'), path.join(dir, 'index.html'))
  assert.equal(resolveFile(dir, '/features/camera'), path.join(dir, 'features', 'camera.html'))
  assert.equal(resolveFile(dir, '/features/camera.html?x=1#top'), path.join(dir, 'features', 'camera.html'))
  assert.equal(resolveFile(dir, '/features/'), path.join(dir, 'features', 'index.html'))
  assert.equal(resolveFile(dir, '/missing'), null)
})

test('a path never leaves the wiki', () => {
  const dir = scratch()
  write(path.join(dir, 'index.html'))
  write(path.join(path.dirname(dir), 'secret.html'))
  assert.equal(resolveFile(dir, '/../secret.html'), null)
  assert.equal(resolveFile(dir, '/%2e%2e/secret.html'), null)
})

test('the home address is an outside IPv4 address, en0 first', () => {
  const v4 = (address, internal = false) => ({ family: 'IPv4', address, internal })
  assert.equal(homeAddress({ lo0: [v4('127.0.0.1', true)], en1: [v4('10.0.0.5')], en0: [v4('192.168.2.10')] }), '192.168.2.10')
  assert.equal(homeAddress({ lo0: [v4('127.0.0.1', true)] }), null)
})

test('each name gets its own wiki, and any other name a list of them', async () => {
  const out = scratch()
  write(path.join(out, 'addix', 'index.html'), 'addix home')
  write(path.join(out, 'addix', '404.html'), 'addix missing')
  write(path.join(out, 'devpal', 'index.html'), 'devpal home')
  const server = http.createServer(handler(out, () => ['addix', 'devpal']))
  await new Promise((resolve) => server.listen(0, resolve))
  const { port } = server.address()
  const get = (host, url = '/') =>
    new Promise((resolve, reject) => {
      http.get({ port, path: url, headers: { host } }, (response) => {
        let body = ''
        response.on('data', (chunk) => (body += chunk))
        response.on('end', () => resolve({ status: response.statusCode, body, type: response.headers['content-type'] }))
      }).on('error', reject)
    })
  try {
    assert.deepEqual(await get('addix.local'), { status: 200, body: 'addix home', type: 'text/html; charset=utf-8' })
    assert.equal((await get('devpal.local')).body, 'devpal home')
    assert.deepEqual(await get('addix.local', '/nope'), { status: 404, body: 'addix missing', type: 'text/html; charset=utf-8' })
    const list = await get('192.168.2.10')
    assert.equal(list.status, 200)
    assert.match(list.body, /addix\.local/)
    assert.match(list.body, /devpal\.local/)
  } finally {
    server.close()
  }
})

test('the machine config can give a wiki its own name', () => {
  const root = scratch()
  fs.mkdirSync(path.join(root, 'johnny-cyberquest', 'docs', '.vitepress'), { recursive: true })
  const config = path.join(root, 'config.json')
  write(config, JSON.stringify({ wikis: { 'johnny-cyberquest': 'cyberquest' } }))
  assert.deepEqual(findWikis(root, chosenNames(config)).map((w) => w.name), ['cyberquest'])
  assert.deepEqual(chosenNames(path.join(root, 'none.json')), {})
})
