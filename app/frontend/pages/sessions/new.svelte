<script>
  import { login } from '~/lib/auth.js'
</script>

<main>
  <section>
    
    <div class="notice">
      Connect your Zalo account to continue.
    </div>
    <button class="btn" onclick={() => login('zalo')}>
      Connect Zalo
    </button>
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