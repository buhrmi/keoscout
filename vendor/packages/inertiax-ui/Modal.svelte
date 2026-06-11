<script module>
  import { mount, unmount } from 'svelte';
  import { Frame } from 'inertiax-svelte'
  import Modal from './Modal.svelte';

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
  import { fade,scale } from 'svelte/transition';
  const { src, close } = $props()
</script>

<div class="modal_wrapper" transition:fade={{duration: 100}}>
  <!-- svelte-ignore a11y_click_events_have_key_events,a11y_no_static_element_interactions -->
  <div class="modal_bg" onclick={close}></div>
  <div class="modal layout" aria-modal="true" role="dialog" in:scale={{duration: 200}}>
    <Frame {src} />
    <nav>
      <button onclick={close} aria-label="Close modal">
        <div class="i-material-symbols-light:close-rounded">Close</div>
      </button>
    </nav>
  </div>
</div>

<style>
.modal_wrapper {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1000;
  display: grid;
  place-items: center;
}
.modal_bg {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: -1;
}
nav {
  grid-area: header;
  display: flex;
  justify-content: flex-end;
  button {
    font-size: 1.5rem;
    
  }
}

@media (min-width: 640px) {
  .modal {
    max-width: 400px;
  }
}
</style>