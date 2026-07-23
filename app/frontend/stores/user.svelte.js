import { writable } from 'svelte/store'
import { page } from 'inertiax-svelte'
export const currentUser = writable(null)

$effect.root(() => {
  $effect(() => {
    currentUser.set(page.props.current_user)
  })
})
