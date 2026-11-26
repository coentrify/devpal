import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { defineConfig } from 'vitepress'

// The wiki serves the docs and the standards. The source root is the project
// root, and a docs page keeps its short URL through the rewrite below. The
// docs overview is the home page.
const PROJECT_ROOT = new URL('../..', import.meta.url).pathname
const DOCS = 'docs'
const STANDARDS = 'standards'
const HOME = `${DOCS}/overview.md`
const PAGE = /\.md$/
const TITLE = /^# (.+)$/m
const INDEX_PAGES = ['index.md', 'overview.md']
const DOCS_ROOT_ORDER = ['architecture.md']
const DOCS_FOLDER_ORDER = ['features', 'development', 'records']
const NEWEST_FIRST = ['log', 'activity', 'changelog']
const GROUP_TITLES = { log: 'Request Log', activity: 'Activity Log' }
const SITE_DATA_MODULE = '/@siteData'
const SETTLE_MILLISECONDS = 500
const WATCHER_IGNORED = ['**/.vitepress/dist/**', '**/.vitepress/cache/**', '**/personas/**', '**/app/.build/**']

function rewrite(page) {
  if (page === HOME) return 'index.md'
  return page.startsWith(`${DOCS}/`) ? page.slice(DOCS.length + 1) : page
}

function title(path, fallback) {
  return readFileSync(path, 'utf8').match(TITLE)?.[1] ?? fallback
}

// Headings are slugged the way GitHub slugs them, so an anchor holds on GitHub,
// in an editor and in the wiki: a log heading `## 12:57` opens at `#1257`.
function githubSlug(heading) {
  return heading.toLowerCase().replace(/[^\p{L}\p{M}\p{Nd}\p{Nl}\p{Pc} -]/gu, '').replace(/ /g, '-')
}

function words(name) {
  return name.replace(PAGE, '').replace(/-/g, ' ').replace(/^./, (letter) => letter.toUpperCase())
}

function ordered(names, order) {
  const rank = (name) => (order.includes(name) ? order.indexOf(name) : order.length)
  return [...names].sort((a, b) => rank(a) - rank(b) || a.localeCompare(b))
}

function url(path) {
  const page = rewrite(path)
  return `/${page.replace(/(^|\/)index\.md$/, '$1').replace(PAGE, '')}`
}

function items(folder, rootOrder = [], folderOrder = []) {
  const names = readdirSync(folder).filter((name) => !name.startsWith('.'))
  const isFolder = (name) => statSync(join(folder, name)).isDirectory()
  const pages = names.filter((name) => PAGE.test(name) && !isFolder(name))
  const overviews = INDEX_PAGES.filter((name) => pages.includes(name))
  const rest = ordered(pages.filter((name) => !INDEX_PAGES.includes(name)), rootOrder)
  const folders = ordered(names.filter(isFolder), folderOrder)
  const page = (name) => ({
    text: title(join(folder, name), words(name)),
    link: url(join(folder, name).slice(PROJECT_ROOT.length)),
  })
  const group = (name) => {
    const children = items(join(folder, name))
    if (NEWEST_FIRST.includes(name)) children.reverse()
    return { text: GROUP_TITLES[name] ?? words(name), collapsed: true, items: children }
  }
  return [...overviews.map(page), ...rest.map(page), ...folders.map(group).filter((entry) => entry.items.length > 0)]
}

function sidebar() {
  return [
    ...items(join(PROJECT_ROOT, DOCS), DOCS_ROOT_ORDER, DOCS_FOLDER_ORDER),
    { text: 'Standards', collapsed: true, items: items(join(PROJECT_ROOT, STANDARDS)) },
  ]
}

// A new or deleted page is picked up in place: once the changes settle, the
// sidebar is rebuilt and the open pages reload. The server never restarts.
const sidebarReload = {
  name: 'sidebar-reload',
  configureServer(server) {
    let timer
    const rebuild = () => {
      server.config.vitepress.site.themeConfig.sidebar = sidebar()
      const siteData = server.moduleGraph.getModuleById(SITE_DATA_MODULE)
      if (siteData) server.moduleGraph.invalidateModule(siteData)
      server.ws.send({ type: 'full-reload' })
    }
    const settle = (file) => {
      if (!PAGE.test(file)) return
      clearTimeout(timer)
      timer = setTimeout(rebuild, SETTLE_MILLISECONDS)
    }
    server.watcher.on('add', settle)
    server.watcher.on('unlink', settle)
  },
}

export default defineConfig({
  title: 'Devpal',
  description: 'A talking companion that lives on a dev machine\'s screen',
  srcDir: '..',
  // Personas stay off the wiki: one made on a machine can carry a real person's voice.
  srcExclude: ['AGENTS.md', 'CLAUDE.md', 'README.md', 'personas/**', 'tools/**', '.claude/**', '.githooks/**'],
  rewrites: rewrite,
  cleanUrls: true,
  lastUpdated: true,
  markdown: { anchor: { slugify: githubSlug } },
  vite: {
    plugins: [sidebarReload],
    server: { headers: { 'Cache-Control': 'no-store' }, watch: { ignored: WATCHER_IGNORED } },
  },
  themeConfig: {
    search: { provider: 'local' },
    nav: [
      { text: 'Plan', link: '/development/plan' },
      { text: 'Architecture', link: '/architecture' },
      { text: 'Standards', link: '/standards/overview' },
    ],
    sidebar: sidebar(),
  },
})
