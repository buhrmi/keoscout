<script>
  import { modal } from 'inertiax-ui'
</script>

<main>
  <section>
    <div class="text-center pt-8 pb-16">
      <p>Account Balance</p>
      <h2>VND 0</h2>
    </div>
  </section>
  <section>
    <div class="card">
      <h3>🎉 Welcome to Keo</h3>
      <p>
        Create your first post to start earning.
      </p>
      <a use:modal href="/dashboard/posts/new" class="btn primary w-full mt-4">
        Create Post
      </a>
    </div>
  </section>
</main>

