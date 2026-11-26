import DefaultTheme from 'vitepress/theme'
import './lightbox.css'
import { setUpLightbox } from './lightbox.mjs'

export default {
  extends: DefaultTheme,
  enhanceApp() {
    if (typeof window !== 'undefined') setUpLightbox()
  },
}
