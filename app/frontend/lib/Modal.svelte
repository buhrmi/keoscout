<script module>
  import { mount, unmount } from 'svelte';
  import { Frame } from 'inertiax-svelte'
  import Modal from '~/lib/Modal.svelte'

  export function modal(node) {
    node.addEventListener('click', (e) => {
      e.preventDefault()
      const href = node.getAttribute('href')
      const modal = mount(Modal, { 
        target: document.body,
        props: {
          src: href,
          close: () => {
            unmount(modal, {outro: true})
          }
        }
      })
    })
  }

</script>

<script>
  const { src, close } = $props()

</script>

<div class="modal">
  <Frame {src} />
  <button onclick={close}>Close</button>
</div>

<style>
.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}
</style>