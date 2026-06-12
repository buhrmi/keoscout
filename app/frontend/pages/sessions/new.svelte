<script>
  import { login } from '~/lib/auth.js'
</script>

<main>
  <section>
    <h2>Continue to Keo</h2>
    <p>
      At this time, we require all new users to authenticate with their Zalo account. Don't worry, you can
      delete your account any time.
    </p>
    <button class="btn mt-8" onclick={() => login('zalo')}>
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