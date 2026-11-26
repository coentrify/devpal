#!/usr/bin/env node
// Serves every project's wiki on the home network, each on a name of its own:
// the addix wiki on addix.local. A project has a wiki when it has a .vitepress folder, in docs or at its root.
//
//   node tools/wikis/wikis.mjs serve [--port 80] [--projects ~/dev]
//   node tools/wikis/wikis.mjs install    starts it with the Mac, and keeps it running
//   node tools/wikis/wikis.mjs uninstall

import { spawn, execFileSync } from 'node:child_process'
import fs from 'node:fs'
import http from 'node:http'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const home = os.homedir()
const devpal = path.join(home, '.devpal')
const label = 'com.coentrify.devpal.wikis'
const agentFile = path.join(home, 'Library', 'LaunchAgents', `${label}.plist`)

/// The folder that holds the projects: the machine's config, else ~/dev.
export function projectsFolder(config = path.join(devpal, 'config.json')) {
  try {
    const chosen = JSON.parse(fs.readFileSync(config, 'utf8')).projects
    if (chosen) return chosen.replace(/^~(?=$|\/)/, home)
  } catch {}
  return path.join(home, 'dev')
}

/// The names the machine's config gives wikis, by project folder: {"johnny-cyberquest": "cyberquest"}.
export function chosenNames(config = path.join(devpal, 'config.json')) {
  try {
    return JSON.parse(fs.readFileSync(config, 'utf8')).wikis ?? {}
  } catch {
    return {}
  }
}

/// The name a project's wiki is served on: its folder name, lowercase, in letters, digits and dashes.
export function hostName(project) {
  return project.toLowerCase().replace(/[^a-z0-9-]+/g, '-').replace(/^-+|-+$/g, '')
}

/// Where a project's wiki config lives, the folder vitepress builds: docs, the root, or null for none.
export function wikiSource(folder) {
  if (fs.existsSync(path.join(folder, 'docs', '.vitepress'))) return 'docs'
  if (fs.existsSync(path.join(folder, '.vitepress'))) return '.'
  return null
}

/// The projects with a wiki, by name: the name the config gives it, else its folder name.
export function findWikis(root, chosen = {}) {
  let entries = []
  try {
    entries = fs.readdirSync(root, { withFileTypes: true })
  } catch {
    return []
  }
  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => ({ name: hostName(chosen[entry.name] ?? entry.name), folder: path.join(root, entry.name), source: wikiSource(path.join(root, entry.name)) }))
    .filter((wiki) => wiki.name && wiki.source)
    .sort((a, b) => a.name.localeCompare(b.name))
}

/// The wiki a request is for, from the name it was sent to.
export function wikiFor(host, names) {
  const name = (host ?? '').toLowerCase().replace(/:\d+$/, '').replace(/\.local\.?$/, '')
  return names.includes(name) ? name : null
}

/// The file a path asks for inside a built wiki, the way the wiki links its pages, or null.
export function resolveFile(dir, urlPath) {
  let wanted
  try {
    wanted = decodeURIComponent(urlPath.split(/[?#]/)[0])
  } catch {
    return null
  }
  const full = path.join(dir, path.normalize(wanted))
  if (full !== dir && !full.startsWith(dir + path.sep)) return null
  for (const candidate of [full, `${full}.html`, path.join(full, 'index.html')]) {
    try {
      if (fs.statSync(candidate).isFile()) return candidate
    } catch {}
  }
  return null
}

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.xml': 'application/xml',
  '.mp4': 'video/mp4',
  '.webm': 'video/webm',
  '.pdf': 'application/pdf',
}

/// The page shown on any other name: a list of the wikis.
export function indexPage(names) {
  const links = names.map((name) => `<li><a href="http://${name}.local/">${name}.local</a></li>`).join('\n')
  return `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Wikis</title>
<style>body{font:16px system-ui;margin:2rem;background:#0b0b10;color:#ddd}a{color:#4fd8ff}</style>
<h1>Wikis</h1><ul>${links}</ul>`
}

/// Answers a request from the built wikis in `out`.
export function handler(out, names) {
  return (request, response) => {
    const name = wikiFor(request.headers.host, names())
    if (!name) {
      response.writeHead(200, { 'content-type': types['.html'] })
      return response.end(indexPage(names()))
    }
    const dir = path.join(out, name)
    const file = resolveFile(dir, request.url ?? '/')
    const missing = path.join(dir, '404.html')
    const served = file ?? (fs.existsSync(missing) ? missing : null)
    if (!served) {
      response.writeHead(404, { 'content-type': types['.txt'] })
      return response.end(`${name} has no page here yet`)
    }
    response.writeHead(file ? 200 : 404, { 'content-type': types[path.extname(served).toLowerCase()] ?? 'application/octet-stream' })
    fs.createReadStream(served).pipe(response)
  }
}

/// The machine's address on the home network.
export function homeAddress(interfaces = os.networkInterfaces()) {
  const named = Object.entries(interfaces)
  const ordered = [...named.filter(([n]) => n === 'en0'), ...named.filter(([n]) => n !== 'en0')]
  for (const [, addresses] of ordered) {
    const found = (addresses ?? []).find((a) => a.family === 'IPv4' && !a.internal)
    if (found) return found.address
  }
  return null
}

function log(message) {
  console.log(`${new Date().toISOString()} ${message}`)
}

/// Builds a wiki beside the one being served, then swaps it in, so a reader never sees half a build.
function build(wiki, out) {
  return new Promise((resolve) => {
    const vitepress = path.join(wiki.folder, 'node_modules', '.bin', 'vitepress')
    if (!fs.existsSync(vitepress)) {
      log(`${wiki.name}: no vitepress, run npm install in ${wiki.folder}`)
      return resolve(false)
    }
    const target = path.join(out, wiki.name)
    const next = `${target}.next`
    fs.rmSync(next, { recursive: true, force: true })
    const started = Date.now()
    const child = spawn(vitepress, ['build', wiki.source, '--outDir', next], { cwd: wiki.folder, stdio: ['ignore', 'ignore', 'pipe'] })
    let errors = ''
    child.stderr.on('data', (chunk) => (errors += chunk))
    child.on('close', (code) => {
      if (code !== 0) {
        log(`${wiki.name}: build failed\n${errors.trim()}`)
        fs.rmSync(next, { recursive: true, force: true })
        return resolve(false)
      }
      fs.rmSync(target, { recursive: true, force: true })
      fs.renameSync(next, target)
      log(`${wiki.name}: built in ${((Date.now() - started) / 1000).toFixed(1)} s`)
      resolve(true)
    })
  })
}

/// Rebuilds a wiki when its pages or its config change, a moment after the last change.
function watch(wiki, rebuild) {
  let timer
  const skip = /(^|\/)(node_modules|\.git|\.claude|\.temp|cache|dist)(\/|$)/
  return fs.watch(wiki.folder, { recursive: true }, (_, file) => {
    // A build writes its own temp files and a stamped copy of the config: those are no change.
    if (!file || skip.test(file) || file.includes('.timestamp-')) return
    if (!/\.(md|mjs|js|ts|mts|vue|css|json|svg|png|jpe?g|gif|webp)$/i.test(file)) return
    clearTimeout(timer)
    timer = setTimeout(rebuild, 2000)
  })
}

/// Publishes the wikis' names on the home network, and again when the address changes.
function publish(names, port) {
  let address = null
  let published = ''
  let children = []
  const stop = () => {
    for (const child of children) child.kill()
    children = []
  }
  const refresh = () => {
    const now = homeAddress()
    const wanted = names().join(' ')
    if (now === address && wanted === published) return
    stop()
    address = now
    published = wanted
    if (!address) return log('no home network address yet')
    for (const name of names()) {
      const child = spawn('/usr/bin/dns-sd', ['-P', `${name} wiki`, '_http._tcp', 'local', String(port), `${name}.local`, address], { stdio: 'ignore' })
      children.push(child)
    }
    log(`published ${names().map((n) => `${n}.local`).join(', ')} on ${address}`)
  }
  refresh()
  const timer = setInterval(refresh, 30_000)
  return () => {
    clearInterval(timer)
    stop()
  }
}

function option(args, flag, fallback) {
  const at = args.indexOf(flag)
  return at >= 0 && args[at + 1] ? args[at + 1] : fallback
}

async function serve(args) {
  const root = option(args, '--projects', projectsFolder())
  const port = Number(option(args, '--port', '80'))
  const out = option(args, '--out', path.join(devpal, 'wikis'))
  fs.mkdirSync(out, { recursive: true })

  let wikis = findWikis(root, chosenNames())
  const names = () => wikis.map((w) => w.name)
  const watchers = new Map()
  const queue = new Map()
  // One build per wiki at a time, and a change during a build builds once more after it.
  const rebuild = (wiki) => {
    const state = queue.get(wiki.name) ?? { running: false, again: false }
    queue.set(wiki.name, state)
    if (state.running) return void (state.again = true)
    state.running = true
    build(wiki, out).then(() => {
      state.running = false
      if (state.again) {
        state.again = false
        rebuild(wiki)
      }
    })
  }
  const follow = () => {
    wikis = findWikis(root, chosenNames())
    for (const wiki of wikis) {
      if (watchers.has(wiki.name)) continue
      watchers.set(wiki.name, watch(wiki, () => rebuild(wiki)))
      rebuild(wiki)
    }
    for (const [name, watcher] of watchers) {
      if (names().includes(name)) continue
      watcher.close()
      watchers.delete(name)
    }
  }
  follow()
  // A project cloned later, or one that gets a wiki, is picked up within a minute.
  setInterval(follow, 60_000)

  const server = http.createServer(handler(out, names))
  server.on('error', (error) => {
    log(`cannot serve on port ${port}: ${error.message}`)
    process.exit(1)
  })
  server.listen(port, () => log(`serving ${names().join(', ') || 'no wikis'} from ${root} on port ${port}`))
  const unpublish = publish(names, port)
  for (const signal of ['SIGINT', 'SIGTERM']) {
    process.on(signal, () => {
      unpublish()
      process.exit(0)
    })
  }
}

function install() {
  const logs = path.join(devpal, 'logs')
  fs.mkdirSync(logs, { recursive: true })
  fs.mkdirSync(path.dirname(agentFile), { recursive: true })
  const script = fileURLToPath(import.meta.url)
  const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${label}</string>
  <key>ProgramArguments</key>
  <array><string>${process.execPath}</string><string>${script}</string><string>serve</string></array>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>${path.dirname(process.execPath)}:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string></dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>${path.join(logs, 'wikis.log')}</string>
  <key>StandardErrorPath</key><string>${path.join(logs, 'wikis.log')}</string>
</dict>
</plist>
`
  uninstall(true)
  fs.writeFileSync(agentFile, plist)
  execFileSync('launchctl', ['bootstrap', `gui/${process.getuid()}`, agentFile])
  console.log(`The wikis now start with the Mac. Log: ${path.join(logs, 'wikis.log')}`)
}

function uninstall(quiet = false) {
  try {
    execFileSync('launchctl', ['bootout', `gui/${process.getuid()}/${label}`], { stdio: 'ignore' })
  } catch {}
  fs.rmSync(agentFile, { force: true })
  if (!quiet) console.log('The wikis no longer start with the Mac.')
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [command, ...args] = process.argv.slice(2)
  if (command === 'serve') await serve(args)
  else if (command === 'install') install()
  else if (command === 'uninstall') uninstall()
  else {
    console.error('usage: wikis.mjs serve [--port 80] [--projects <folder>] [--out <folder>] | install | uninstall')
    process.exit(2)
  }
}
