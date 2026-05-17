import { svelte } from '@sveltejs/vite-plugin-svelte'
import inertia from '@inertiajs/vite'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import UnoCSS from 'unocss/vite'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    UnoCSS(),
    inertia(),
    svelte(),
  ],
})
