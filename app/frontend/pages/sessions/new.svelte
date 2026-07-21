<script>
  import { login } from '~/lib/auth.js'
  import { appKit } from '~/lib/appkit.ts'
  import { currentUser } from '~/stores/user.svelte.js'
  
  const { close } = $props()

  $effect(() => {
    if ($currentUser) {
      close(false)
    }
  })
</script>

<main>
  <section>
    <p class="text-center">Connect your wallet to continue.</p>
    <!-- <button class="btn mt-8" onclick={() => login('zalo')}>
      Connect Zalo
    </button> -->
    <appkit-button />
  </section>
</main>


<style>
  .notice {
    border: 1px solid #888;
    padding: 1rem;
    margin-bottom: 1rem;
    border-radius: 6px;
    background-color: #222;
  }
</style>