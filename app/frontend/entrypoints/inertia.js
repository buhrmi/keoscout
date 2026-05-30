import '@unocss/reset/tailwind.css'
import 'virtual:uno.css'
import '~/assets/global.css'

import Default from "~/layouts/default.svelte"


import { createInertiaApp, router } from '@inertiajs/svelte'

createInertiaApp({
  pages: "../pages",
  layout: () => Default,
})

// add .loading class to body while inertia is loading
document.addEventListener("inertia:start", () => {
  document.body.classList.add("loading")
})

// remove .loading class from body when inertia finishes loading
document.addEventListener("inertia:finish", () => {
  document.body.classList.remove("loading")
  document.querySelectorAll(".loader").forEach(el => el.classList.remove("loader"))
})

// add the loader class to all .btn elements when they are clicked
document.addEventListener("click", (ev) => {
  const btn = ev.target.closest(".btn")
  if (btn) {
    btn.classList.add("loader")
  }
})


window.addEventListener('message', function(event) {
  if (event.data == 'session-created') {
    router.reload()
  }
})