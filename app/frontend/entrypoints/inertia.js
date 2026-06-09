import '@unocss/reset/tailwind.css'
import 'virtual:uno.css'
import '~/assets/global.css'

import Default from "~/layouts/default.svelte"

import { createInertiaApp } from 'inertiax-svelte'

createInertiaApp({
  pages: "../pages",
  layout: () => Default,
  async withApp(app, { ssr }) {
    if (ssr) return
    import('~/lib/setup')
  }
})
