// Every image in a page enlarges on a click to the full window width.
// The listeners sit on the document, so a hot reload that replaces a page's
// images never leaves an image without them.
const PAGE_IMAGES = '.vp-doc img'
const STEP_BY_KEY = { ArrowRight: 1, ArrowLeft: -1 }

export function setUpLightbox() {
  const overlay = document.createElement('div')
  overlay.className = 'lightbox'
  overlay.hidden = true
  const picture = document.createElement('img')
  picture.className = 'lightbox-image'
  const counter = document.createElement('div')
  counter.className = 'lightbox-counter'
  overlay.append(picture, counter)
  document.body.append(overlay)

  let images = []
  let position = 0

  function show(index) {
    position = (index + images.length) % images.length
    picture.src = images[position].currentSrc || images[position].src
    picture.alt = images[position].alt
    counter.textContent = `${position + 1} / ${images.length}`
    overlay.hidden = false
  }

  function close() {
    overlay.hidden = true
  }

  document.addEventListener('click', (event) => {
    if (!overlay.hidden) {
      close()
      return
    }
    const image = event.target.closest?.(PAGE_IMAGES)
    if (!image) return
    images = [...document.querySelectorAll(PAGE_IMAGES)]
    show(images.indexOf(image))
  })

  document.addEventListener('keydown', (event) => {
    if (overlay.hidden) return
    if (event.key === 'Escape') close()
    else if (event.key in STEP_BY_KEY) show(position + STEP_BY_KEY[event.key])
  })
}
