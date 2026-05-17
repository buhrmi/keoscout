import '@unocss/reset/tailwind.css'
import 'virtual:uno.css'
import '~/assets/global.css'

import { createInertiaApp } from '@inertiajs/svelte'

createInertiaApp({
  pages: "../pages",

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: "brackets" }
    },
  },
})
